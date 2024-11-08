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
    struct curl_slist *hosts;
    SCProgress *scProgress;
    NSMutableData *headerBuffer;
    NSMutableData *bodyBuffer;
    NSMutableData *errorBuffer;
    struct curl_slist *headers;
}

size_t cb(char *data, size_t size, size_t nmemb, void *userdata)
{
    NSUInteger length = size * nmemb;

//    NSLog(@"received %lu bytes", (unsigned long)length);

    [(__bridge NSMutableData *)userdata appendBytes:data length:length];

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

        [self set:CURLOPT_PROTOCOLS_STR toString:conf.allowedProtocols];
        curl_easy_setopt(curl, CURLOPT_AUTOREFERER, conf.autoReferer);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, conf.followLocation);

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

        _progress = conf.progress != nil ? conf.progress : [NSProgress progressWithTotalUnitCount:0];
        scProgress = [[SCProgress alloc] initWith:self.progress];
        curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, progressCb);
        curl_easy_setopt(curl, CURLOPT_XFERINFODATA, scProgress);
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);

        headerBuffer = [[NSMutableData alloc] init];
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, headerBuffer);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, cb);

        bodyBuffer = [[NSMutableData alloc] init];
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, bodyBuffer);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, cb);

        errorBuffer = [[NSMutableData alloc] initWithLength:CURL_ERROR_SIZE];
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

- (void)resume:(CompletionHandler)completionHandler
{
    switch (self.state) {
        case NSURLSessionTaskStateSuspended:
            break;

        case NSURLSessionTaskStateCanceling:
            completionHandler(nil, nil, self.error);
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

            completionHandler(nil, nil, self.error);

            return;
        }

        self->_response = [self parseResponse];
        self->_state = NSURLSessionTaskStateCompleted;

        if (res)
        {
            NSString* message = [[NSString alloc] initWithData:self->errorBuffer encoding:NSUTF8StringEncoding];
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:res userInfo:@{NSLocalizedDescriptionKey: message}];

            self->_error = error;

            [self cleanup];

            completionHandler(nil, self.response, error);
        }
        else {
            NSData *data = self->bodyBuffer;

            [self cleanup];

            completionHandler(data, self.response, nil);
        }
    });
}


// MARK: - Private Methods

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

- (nullable NSHTTPURLResponse *)parseResponse
{
//    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    if (!headerBuffer || headerBuffer.length < 1)
    {
        return nil;
    }

    NSArray<NSString *> *lines = [[[NSString alloc] initWithData:headerBuffer encoding:NSUTF8StringEncoding]
                                          componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (lines.count < 1 || (lines.count == 1 && [lines[0] isEqualToString:@""]))
    {
        return nil;
    }

    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"(HTTP/[\\d.]+).*(\\d{3})" options:NSRegularExpressionCaseInsensitive error:nil];
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

    NSData *urlData = [[NSData alloc] initWithBytes:urlBytes length:strlen(urlBytes)];
    NSString *urlString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];

    NSURL *url = self.originalRequest.URL;

    if (urlString.length > 0)
    {
        url = [[NSURL alloc] initWithString:urlString];
    }

    return [[NSHTTPURLResponse alloc] initWithURL:url
                                       statusCode:code
                                      HTTPVersion:version
                                     headerFields:headers];
}

@end
