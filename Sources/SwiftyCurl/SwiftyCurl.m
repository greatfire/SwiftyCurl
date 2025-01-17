//
//  SwiftyCurl.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 25.10.24.
//

#import "SwiftyCurl.h"
#import "Private/SCTask-Private.h"
#import <WebKit/WebKit.h>
#import <curl/curl.h>

@implementation SwiftyCurl
{
    NSUInteger ticket;
}

+ (NSString *)libcurlVersion
{
    curl_version_info_data *info = curl_version_info(CURLVERSION_NOW);

    NSMutableArray<NSString *> *protocols = [NSMutableArray new];
    for (size_t i = 0; i < sizeof(info->protocols); i++)
    {
        [protocols addObject:[NSString stringWithCString:info->protocols[i] encoding:NSUTF8StringEncoding]];
    }

    NSMutableArray<NSString *> *features = [NSMutableArray new];
    for (size_t i = 0; i < sizeof(info->feature_names); i++)
    {
        [features addObject:[NSString stringWithCString:info->feature_names[i] encoding:NSUTF8StringEncoding]];
    }

    return [NSString stringWithFormat:@"libcurl %s using %s and libz %s on %s (supported protocols: %@), (supported features: %@)",
            info->version,
            info->ssl_version,
            info->libz_version,
            info->host,
            [protocols componentsJoinedByString:@", "],
            [features componentsJoinedByString:@", "]
    ];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        curl_global_init(CURL_GLOBAL_ALL);

        self.queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
        self.allowedProtocols = @"HTTP,HTTPS";
        self.authMethod = Any;
        self.tlsCertsCombinedPem = [[NSBundle bundleWithURL:
                                     [[NSBundle bundleForClass:self.class]
                                      URLForResource:@"certs" withExtension:@"bundle"]]
                                    URLForResource:@"cacert" withExtension:@"pem"];
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
    [self performWithRequest:[NSURLRequest requestWithURL:url] progress:progress completionHandler:completionHandler];
}

- (void)performWithRequest:(NSURLRequest *)request
                  progress:(nullable NSProgress *)progress
         completionHandler:(CompletionHandler)completionHandler
{
    [[self taskWithRequest:request progress:progress]
     resume:completionHandler];
}

- (nullable SCTask *)taskWithURL:(nonnull NSURL *)url
{
    return [self taskWithRequest:[NSURLRequest requestWithURL:url]];
}

- (nullable SCTask *)taskWithRequest:(NSURLRequest *)request
{
    return [self taskWithRequest:request progress:nil];
}

- (nullable SCTask *)taskWithRequest:(nonnull NSURLRequest *)request progress:(nullable NSProgress *)progress
{
    ticket++;

    SCConfig *conf = [[SCConfig alloc] init];
    conf.ticket = ticket;
    conf.progress = progress;
    conf.request = request;
    conf.queue = self.queue;
    conf.allowedProtocols = self.allowedProtocols;
    conf.autoReferer = self.autoReferer;
    conf.followLocation = self.followLocation;
    conf.userAgent = self.userAgent;
    conf.cookieJar = self.cookieJar;
    conf.resolve = self.resolve;
    conf.tlsIgnoreInvalidCertChain = self.tlsIgnoreInvalidCertChain;
    conf.tlsIgnoreInvalidHost = self.tlsIgnoreInvalidHost;
    conf.tlsCertsFolder = self.tlsCertsFolder;
    conf.tlsCertsCombinedPem = self.tlsCertsCombinedPem;
    conf.authMethod = [self getAuth:self.authMethod];
    conf.username = self.username;
    conf.password = self.password;
    conf.bearerToken = self.bearerToken;
    conf.awsSigV4 = self.awsSigV4;
    conf.proxyDict = self.proxyDict;
    conf.socksProxyResolves = self.socksProxyResolves;
    conf.verbose = self.verbose;

    SCTask *task = [[SCTask alloc] initWith:conf];
    task.delegate = self.delegate;

    return task;
}

- (void)dealloc
{
    curl_global_cleanup();
}

static WKWebView *webView;

+ (void)defaultUserAgent:(nonnull void (^)(NSString * _Nullable __strong))completionHandler
{
    webView = [[WKWebView alloc] initWithFrame:CGRectZero];

    [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        webView = nil;

        completionHandler((NSString *)result);
    }];
}



#pragma mark Private Methods

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

        case Ntlm:
            return CURLAUTH_NTLM;

        case AnySafe:
            return CURLAUTH_ANYSAFE;

        default:
            return CURLAUTH_ANY;
    }
}

@end
