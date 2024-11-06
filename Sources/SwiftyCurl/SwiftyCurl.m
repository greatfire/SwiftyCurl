//
//  SwiftyCurl.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 25.10.24.
//

#import "SwiftyCurl.h"
#import "SCProgress.h"
#import <curl/curl.h>

@implementation SwiftyCurl

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

    return progress.cancelled ? 1 : 0;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        curl_global_init(CURL_GLOBAL_ALL);

        self.queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
        self.allowedProtocols = @"HTTP,HTTPS";
        self.authMethod = Any;
    }

    return self;
}

- (void)performWithURL:(nonnull NSURL *)url completionHandler:(nonnull CompletionHandler)completionHandler
{
    [self performWithURL:url progress:nil completionHandler:completionHandler];
}

- (void)performWithRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull CompletionHandler)completionHandler
{
    [self performWithRequest:request progress:nil completionHandler:completionHandler];
}

- (void)performWithURL:(NSURL *)url
              progress:(nullable NSProgress *)progress
     completionHandler:(CompletionHandler)completionHandler
{
    [self performWithRequest:[[NSURLRequest alloc] initWithURL:url] progress:progress completionHandler:completionHandler];
}

- (void)performWithRequest:(NSURLRequest *)request
                  progress:(nullable NSProgress *)progress
         completionHandler:(CompletionHandler)completionHandler
{
    dispatch_async(self.queue, ^{
        CURL *curl = curl_easy_init();

        if (!curl)
        {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"CURL could not be initialized!"}];
            completionHandler(nil, nil, error);

            return;
        }

        curl_easy_setopt(curl, CURLOPT_PROTOCOLS_STR, [self.allowedProtocols cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(curl, CURLOPT_AUTOREFERER, self.autoReferer ? 1 : 0);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, self.followLocation ? 1 : 0);

        if (request.HTTPShouldHandleCookies && self.cookieJar.fileURL)
        {
            curl_easy_setopt(curl, CURLOPT_COOKIEFILE, [self.cookieJar.path cStringUsingEncoding:NSUTF8StringEncoding]);
            curl_easy_setopt(curl, CURLOPT_COOKIEJAR, [self.cookieJar.path cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        struct curl_slist *hosts = NULL; // Keep it around until after the request is performed.

        if (self.resolve.count > 0)
        {
            for (SCResolveEntry *entry in self.resolve)
            {
                hosts = curl_slist_append(hosts, [entry.description cStringUsingEncoding:NSUTF8StringEncoding]);
            }

            curl_easy_setopt(curl, CURLOPT_RESOLVE, hosts);
        }

        curl_easy_setopt(curl, CURLOPT_HTTPAUTH, [self getAuth:self.authMethod]);
        curl_easy_setopt(curl, CURLOPT_USERNAME, [self.username cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(curl, CURLOPT_PASSWORD, [self.password cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(curl, CURLOPT_XOAUTH2_BEARER, [self.bearerToken cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(curl, CURLOPT_AWS_SIGV4, [self.awsSigV4 cStringUsingEncoding:NSUTF8StringEncoding]);

        // Only allow this to be set during development!
        if (DEBUG) {
            curl_easy_setopt(curl, CURLOPT_VERBOSE, self.verbose ? 1 : 0);
        }

        SCProgress *scProgress;  // Keep outside of block, otherwise we will crash, because it got cleaned up again!

        if (progress)
        {
            scProgress = [[SCProgress alloc] initWith:progress];

            curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, progressCb);
            curl_easy_setopt(curl, CURLOPT_XFERINFODATA, scProgress);
            curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0);
        }

        NSMutableData *headerBuffer = [[NSMutableData alloc] init];
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, headerBuffer);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, cb);

        NSMutableData *bodyBuffer = [[NSMutableData alloc] init];
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, bodyBuffer);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, cb);

        NSMutableData *errorBuffer = [[NSMutableData alloc] initWithLength:CURL_ERROR_SIZE];
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errorBuffer.bytes);

        if ([request.HTTPMethod isEqualToString:@"GET"])
        {
            curl_easy_setopt(curl, CURLOPT_HTTPGET, 1);
        }
        else if ([request.HTTPMethod isEqualToString:@"POST"])
        {
            curl_easy_setopt(curl, CURLOPT_POST, 1);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, request.HTTPBody.length);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS, request.HTTPBody.bytes);
        }
        else if ([request.HTTPMethod isEqualToString:@"PUT"])
        {
            curl_easy_setopt(curl, CURLOPT_POST, 1);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, request.HTTPBody.length);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS, request.HTTPBody.bytes);
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST,
                             [@"PUT" cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        else {
            curl_easy_setopt(curl, CURLOPT_POST, 0);
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST,
                             [request.HTTPMethod cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        curl_easy_setopt(curl, CURLOPT_URL,
                         [request.URL.absoluteString cStringUsingEncoding:NSUTF8StringEncoding]);

        struct curl_slist *headers = NULL;
        for (NSString *key in request.allHTTPHeaderFields.allKeys)
        {
            headers = curl_slist_append(headers,
                                        [[NSString stringWithFormat:
                                          @"%@: %@", key, request.allHTTPHeaderFields[key]]
                                         cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

        curl_easy_setopt(curl, CURLOPT_TIMEOUT, request.timeoutInterval);

        CURLcode res = curl_easy_perform(curl);

        curl_slist_free_all(headers);
        curl_slist_free_all(hosts);

        NSHTTPURLResponse *response = [self parseResponse:headerBuffer from:curl ofUrl:request.URL];

        curl_easy_cleanup(curl);

        if (res)
        {
            NSString* message = [[NSString alloc] initWithData:errorBuffer encoding:NSUTF8StringEncoding];
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:res userInfo:@{NSLocalizedDescriptionKey: message}];

            completionHandler(nil, response, error);
        }
        else {
            completionHandler(bodyBuffer, response, nil);
        }
    });
}

- (void)dealloc
{
    curl_global_cleanup();
}

// MARK: - Private Methods

- (long)getAuth:(SwiftyCurlAuthMethods)method
{
    switch (method) {
        case Basic:
            return CURLAUTH_BASIC;

        case Digest:
            return CURLAUTH_DIGEST;

        case DigestIe:
            return CURLAUTH_DIGEST_IE;

        case Bearer:
            return CURLAUTH_BEARER;

        case Negotiate:
            return CURLAUTH_NEGOTIATE;

        case Ntlm:
            return CURLAUTH_NTLM;

        case AnySafe:
            return CURLAUTH_ANYSAFE;

        default:
            return CURLAUTH_ANY;
    }
}

- (nullable NSHTTPURLResponse *)parseResponse:(NSData *)data from:(CURL *)curl ofUrl:(NSURL *)url
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
