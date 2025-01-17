//
//  SCTask.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import "SCTask.h"
#import "Private/SCTask-Private.h"
#import "Private/SCProgress.h"
#import <curl/curl.h>

@implementation SCTask
{
    CURL *curl;
    dispatch_queue_t queue;
    BOOL followLocation;
    NSURLCredential *credential;
    struct curl_slist *hosts;
    SCProgress *scProgress;
    NSMutableData *headerBuffer;
    NSMutableData *bodyBuffer;
    NSMutableData *errorBuffer;
    struct curl_slist *headers;
}

size_t headerCb(char *data, size_t size, size_t nmemb, void *userdata)
{
    NSUInteger length = size * nmemb;

    SCTask *task = (__bridge SCTask *)userdata;

    NSData *line = [NSData dataWithBytes:data length:length];
    [task->headerBuffer appendData:line];

    NSString *string = [[NSString alloc] initWithData:line encoding:NSASCIIStringEncoding];

    // Collecting all header lines first.
    if (![string isEqualToString:@"\r\n"])
    {
        return length;
    }

    NSHTTPURLResponse *response = [task parseResponse:task->headerBuffer];
    task->_response = response;

    if (response.statusCode >= 300 && response.statusCode < 400)
    {
        NSString *location = response.allHeaderFields[@"Location"];
        NSURL *url = [NSURL URLWithString:location];

        if (url)
        {
            NSMutableURLRequest *redirect = task.originalRequest.mutableCopy;
            redirect.URL = url;

            if (response.statusCode == 302 /* Found (Moved Temporarily) */ || response.statusCode == 303 /* See Other */)
            {
                redirect.HTTPMethod = @"GET";
            }

            if (task->followLocation && [task.delegate respondsToSelector:@selector(task:willPerformHTTPRedirection:newRequest:)])
            {
                return [task.delegate task:task willPerformHTTPRedirection:response newRequest:redirect] ? length : -1;
            }
            else if (!task->followLocation && [task.delegate respondsToSelector:@selector(task:isHTTPRedirection:newRequest:)])
            {
                [task.delegate task:task isHTTPRedirection:response newRequest:redirect];
                return length;
            }
        }
    }
    else if ((response.statusCode == 401 /* Unauthorized */ || response.statusCode == 407 /* Proxy Authentication Required */)
             && [task.delegate respondsToSelector:@selector(task:didReceiveChallenge:)])
    {
        NSURL *url = response.URL;

        if (url)
        {

            NSString *auth = response.allHeaderFields[response.statusCode == 401 ? @"WWW-Authenticate" : @"Proxy-Authenticate"];
            NSString *realm;
            NSString *method;

            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"realm=\"(.*?)\"" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:auth options:0 range:NSMakeRange(0, auth.length)];
            NSRange range = [matches.firstObject rangeAtIndex:1];

            if (range.location != NSNotFound)
            {
                realm = [auth substringWithRange:range];
            }

            if ([auth.lowercaseString hasPrefix:@"basic"])
            {
                method = NSURLAuthenticationMethodHTTPBasic;
            }
            else if ([auth.lowercaseString hasPrefix:@"digest"])
            {
                method = NSURLAuthenticationMethodHTTPDigest;
            }

            NSURLProtectionSpace *ps;

            if (response.statusCode == 401)
            {
                ps = [[NSURLProtectionSpace alloc]
                      initWithHost:url.host
                      port:url.port.integerValue
                      protocol:response.URL.scheme
                      realm:realm
                      authenticationMethod:method];
            }
            else {
                NSString *type;

                if ([url.scheme.lowercaseString isEqualToString:@"http"])
                {
                    type = NSURLProtectionSpaceHTTPProxy;
                }
                else {
                    type = NSURLProtectionSpaceHTTPSProxy;
                }

                ps = [[NSURLProtectionSpace alloc]
                      initWithProxyHost:url.host
                      port:url.port.integerValue
                      type:type
                      realm:realm
                      authenticationMethod:method];
            }

            NSURLAuthenticationChallenge *challenge = [[NSURLAuthenticationChallenge alloc]
                                                       initWithProtectionSpace:ps
                                                       proposedCredential:task->credential
                                                       previousFailureCount:0
                                                       failureResponse:response
                                                       error:nil
                                                       sender:task];

            return [task.delegate task:task didReceiveChallenge:challenge] ? length : -1;
        }
    }

    if ([task.delegate respondsToSelector:@selector(task:didReceiveResponse:)])
    {
        return [task.delegate task:task didReceiveResponse:task.response] ? length : -1;
    }

    return length;
}

size_t bodyCb(char *data, size_t size, size_t nmemb, void *userdata)
{
    NSUInteger length = size * nmemb;
//    NSLog(@"received %lu bytes", (unsigned long)length);

    SCTask *task = (__bridge SCTask *)userdata;
    NSData *nsData = [NSData dataWithBytes:data length:length];
    [task->bodyBuffer appendData:nsData];

    if ([task.delegate respondsToSelector:@selector(task:didReceiveData:)])
    {
        return [task.delegate task:task didReceiveData:nsData] ? length : -1;
    }

    return length;
}

int progressCb(void *clientp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow)
{
    SCProgress *progress = (__bridge SCProgress *)clientp;

    [progress applyUlTotal:ultotal ulNow:ulnow dlTotal:dltotal dlNow:dlnow];

    return progress.cancelled;
}


- (nullable instancetype)initWith:(nonnull SCConfig *)conf
{
    self = [super init];

    if (self)
    {
        curl = curl_easy_init();

        if (!curl)
        {
            return nil;
        }

        _taskIdentifier = conf.ticket;
        _state = NSURLSessionTaskStateSuspended;
        _originalRequest = conf.request;
        queue = conf.queue;
        followLocation = conf.followLocation;

        if (conf.username.length > 0 || conf.password.length > 0)
        {
            credential = [NSURLCredential credentialWithUser:conf.username password:conf.password persistence:NSURLCredentialPersistenceForSession];
        }

        [self set:CURLOPT_PROTOCOLS_STR toString:conf.allowedProtocols];
        curl_easy_setopt(curl, CURLOPT_AUTOREFERER, conf.autoReferer);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, conf.followLocation);
        [self set:CURLOPT_USERAGENT toString:conf.userAgent];

        if (conf.request.HTTPShouldHandleCookies && conf.cookieJar.fileURL)
        {
            [self set:CURLOPT_COOKIEFILE toString:conf.cookieJar.path];
            [self set:CURLOPT_COOKIEJAR toString:conf.cookieJar.path];
        }

        hosts = NULL;
        if (conf.resolve.count > 0)
        {
            for (SCResolveEntry *entry in conf.resolve)
            {
                hosts = curl_slist_append(hosts, [entry.description cStringUsingEncoding:NSUTF8StringEncoding]);
            }

            curl_easy_setopt(curl, CURLOPT_RESOLVE, hosts);
        }

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, !conf.tlsIgnoreInvalidCertChain);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, conf.tlsIgnoreInvalidHost ? 0 : 2);
        [self set:CURLOPT_CAPATH toString:conf.tlsCertsFolder.path];
        [self set:CURLOPT_CAINFO toString:conf.tlsCertsCombinedPem.path];

        curl_easy_setopt(curl, CURLOPT_HTTPAUTH, conf.authMethod);
        [self set:CURLOPT_USERNAME toString:conf.username];
        [self set:CURLOPT_PASSWORD toString:conf.password];
        [self set:CURLOPT_XOAUTH2_BEARER toString:conf.bearerToken];
        [self set:CURLOPT_AWS_SIGV4 toString:conf.awsSigV4];

        if (conf.proxyDict.count > 0)
        {
            NSString *type = conf.proxyDict[(__bridge NSString *)kCFProxyTypeKey];

            if ([type isEqualToString:(__bridge NSString *)kCFProxyTypeSOCKS])
            {
                curl_easy_setopt(curl, CURLOPT_PROXYTYPE, [self socksProxyType:conf]);

                [self set:CURLOPT_PROXY toString:conf.proxyDict[(__bridge NSString *)kCFStreamPropertySOCKSProxyHost]];
                curl_easy_setopt(curl, CURLOPT_PROXYPORT, ((NSNumber *)conf.proxyDict[(__bridge NSString *)kCFStreamPropertySOCKSProxyPort]).longValue);

                [self set:CURLOPT_PROXYUSERNAME toString:conf.proxyDict[(__bridge NSString *)kCFStreamPropertySOCKSUser]];
                [self set:CURLOPT_PROXYPASSWORD toString:conf.proxyDict[(__bridge NSString *)kCFStreamPropertySOCKSPassword]];
            }
            else if ([type isEqualToString:(__bridge NSString *)kCFProxyTypeHTTP])
            {
                curl_easy_setopt(curl, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [self set:CURLOPT_PROXY toString:conf.proxyDict[(__bridge NSString *)kCFStreamPropertyHTTPProxyHost]];
                curl_easy_setopt(curl, CURLOPT_PROXYPORT, ((NSNumber *)conf.proxyDict[(__bridge NSString *)kCFStreamPropertyHTTPProxyPort]).longValue);
#pragma clang diagnostic pop
            }
            else if ([type isEqualToString:(__bridge NSString *)kCFProxyTypeHTTPS])
            {
                curl_easy_setopt(curl, CURLOPT_PROXYTYPE, CURLPROXY_HTTPS);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [self set:CURLOPT_PROXY toString:conf.proxyDict[(__bridge NSString *)kCFStreamPropertyHTTPSProxyHost]];
                curl_easy_setopt(curl, CURLOPT_PROXYPORT, ((NSNumber *)conf.proxyDict[(__bridge NSString *)kCFStreamPropertyHTTPSProxyPort]).longValue);
#pragma clang diagnostic pop
            }
        }

#ifdef DEBUG
        // Only allow this to be set during development!
        curl_easy_setopt(curl, CURLOPT_VERBOSE, conf.verbose);
#endif

        _progress = conf.progress ? conf.progress : [NSProgress progressWithTotalUnitCount:0];
        scProgress = [[SCProgress alloc] initWith:self.progress];
        curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, progressCb);
        curl_easy_setopt(curl, CURLOPT_XFERINFODATA, scProgress);
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);

        headerBuffer = [NSMutableData new];
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, self);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, headerCb);

        bodyBuffer = [NSMutableData new];
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, self);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, bodyCb);

        errorBuffer = [NSMutableData dataWithLength:CURL_ERROR_SIZE];
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errorBuffer.bytes);

        if ([conf.request.HTTPMethod isEqualToString:@"GET"])
        {
            curl_easy_setopt(curl, CURLOPT_HTTPGET, 1);
        }
        else if ([conf.request.HTTPMethod isEqualToString:@"POST"])
        {
            curl_easy_setopt(curl, CURLOPT_POST, 1);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, conf.request.HTTPBody.length);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS, conf.request.HTTPBody.bytes);
        }
        else if ([conf.request.HTTPMethod isEqualToString:@"PUT"])
        {
            curl_easy_setopt(curl, CURLOPT_POST, 1);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, conf.request.HTTPBody.length);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS, conf.request.HTTPBody.bytes);
            [self set: CURLOPT_CUSTOMREQUEST toString:@"PUT"];
        }
        else {
            curl_easy_setopt(curl, CURLOPT_POST, 0);
            [self set: CURLOPT_CUSTOMREQUEST toString:conf.request.HTTPMethod];
        }

        [self set:CURLOPT_URL toString:conf.request.URL.absoluteString];

        headers = NULL;
        for (NSString *key in conf.request.allHTTPHeaderFields.allKeys)
        {
            headers = curl_slist_append(headers,
                                        [[NSString stringWithFormat:
                                          @"%@: %@", key, conf.request.allHTTPHeaderFields[key]]
                                         cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

        curl_easy_setopt(curl, CURLOPT_TIMEOUT, conf.request.timeoutInterval);
    }

    return self;
}

- (void)cancel
{
    switch (self.state) {
        case NSURLSessionTaskStateRunning:
            _state = NSURLSessionTaskStateCanceling;
            _error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            break;

        case NSURLSessionTaskStateSuspended:
            _state = NSURLSessionTaskStateCanceling;
            _error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];

            [self cleanup];
            break;

        default:
            return;
    }
}

- (void)resume:(nullable CompletionHandler)completionHandler
{
    switch (self.state) {
        case NSURLSessionTaskStateSuspended:
            break;

        case NSURLSessionTaskStateCanceling:
            if (completionHandler)
            {
                completionHandler(nil, nil, self.error);
            }

            return;

        default:
            return;
    }

    _state = NSURLSessionTaskStateRunning;

    dispatch_async(queue, ^{
        CURLcode res = curl_easy_perform(self->curl);

        // We got cancelled during perform!
        if (self.state == NSURLSessionTaskStateCanceling)
        {
            [self cleanup];

            if (completionHandler)
            {
                completionHandler(nil, nil, self.error);
            }

            return;
        }

        self->_state = NSURLSessionTaskStateCompleted;

        if (res)
        {
            NSString* message = [[NSString alloc] initWithData:self->errorBuffer encoding:NSUTF8StringEncoding];
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:res userInfo:@{NSLocalizedDescriptionKey: message}];

            self->_error = error;

            [self cleanup];

            if (completionHandler)
            {
                completionHandler(nil, self.response, error);
            }
        }
        else {
            NSData *data = self->bodyBuffer;

            [self cleanup];

            if (completionHandler)
            {
                completionHandler(data, self.response, nil);
            }
        }

        if ([self.delegate respondsToSelector:@selector(task:didCompleteWithError:)])
        {
            [self.delegate task:self didCompleteWithError:self->_error];
        }
    });
}

- (void)dealloc
{
    [self cleanup];
}


#pragma mark Private Methods

- (void)cleanup
{
    curl_easy_cleanup(curl);
    curl = NULL;

    queue = NULL;

    curl_slist_free_all(hosts);
    hosts = NULL;

    scProgress = nil;
    headerBuffer = nil;
    bodyBuffer = nil;
    errorBuffer = nil;

    curl_slist_free_all(headers);
    headers = NULL;
}

- (long)socksProxyType:(SCConfig *)conf
{
    NSString *version = conf.proxyDict[(__bridge NSString *)kCFStreamPropertySOCKSVersion];

    if ([version isEqualToString:(__bridge NSString *)kCFStreamSocketSOCKSVersion4])
    {
        return conf.socksProxyResolves ? CURLPROXY_SOCKS4A : CURLPROXY_SOCKS4;
    }
    else if ([version isEqualToString:(__bridge NSString *)kCFStreamSocketSOCKSVersion5]) {
        return conf.socksProxyResolves ? CURLPROXY_SOCKS5_HOSTNAME : CURLPROXY_SOCKS5;
    }

    return -1;
}

- (void)set:(CURLoption)option toString:(NSString *)string
{
    curl_easy_setopt(curl, option, [string cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (nullable NSHTTPURLResponse *)parseResponse:(NSData *)data
{
//    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    if (!data || data.length < 1)
    {
        return nil;
    }

    NSArray<NSString *> *lines = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                          componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (lines.count < 1 || (lines.count == 1 && [lines[0] isEqualToString:@""]))
    {
        return nil;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(HTTP/[\\d.]+).*(\\d{3})" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableDictionary<NSString *, NSString *> *headers = [[NSMutableDictionary alloc] init];
    NSInteger code = 400;
    NSString *version;

    for (NSString *line in lines) {
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:line options:NSMatchingReportCompletion range:NSMakeRange(0, line.length)];

        if (matches.count > 0)
        {
            if (matches[0].numberOfRanges > 1)
            {
                version = [line substringWithRange:[matches[0] rangeAtIndex:1]];
            }

            if (matches[0].numberOfRanges > 2)
            {
                code = [line substringWithRange:[matches[0] rangeAtIndex:2]].integerValue;
            }
            else {
                long c;
                curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &c);

                code = c;
            }

            // Another header starts. The earlier ones are from redirects/authentication repeats.
            // We're only interested in the last request.
            [headers removeAllObjects];
        }
        else {
            NSMutableArray<NSString *> *parts = [[line componentsSeparatedByString:@":"] mutableCopy];

            if (parts.count > 1)
            {
                NSString *key = parts[0];
                [parts removeObjectAtIndex:0];

                headers[key] = [[parts componentsJoinedByString:@":"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }

    // TODO: As per documentation, this *should* give us the location where curl got redirected
    // to, but unfortunately, this seems broken.
    // https://curl.se/libcurl/c/CURLINFO_EFFECTIVE_URL.html
    char *urlBytes = NULL;
    curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &urlBytes);

    NSData *urlData = [NSData dataWithBytes:urlBytes length:strlen(urlBytes)];
    NSString *urlString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];

    NSURL *url = self.originalRequest.URL;

    if (urlString.length > 0)
    {
        url = [NSURL URLWithString:urlString];
    }

    return [[NSHTTPURLResponse alloc] initWithURL:url
                                       statusCode:code
                                      HTTPVersion:version
                                     headerFields:headers];
}

#pragma mark NSURLAuthenticationChallengeSender

- (void)cancelAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge
{
    [self cancel];
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge
{
    // Nothing to do.
}

- (void)useCredential:(nonnull NSURLCredential *)credential forAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge
{
    [NSException raise:@"Unsupported" format:@"Too late. You need to update credentials on the `SwiftyCurl` object and issue another `SCTask` using it."];
}

@end
