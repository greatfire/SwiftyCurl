//
//  SwiftyCurl.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 25.10.24.
//

#import <Foundation/Foundation.h>
#import "SCResolveEntry.h"
#import "SCTask.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A nice abstraction over the wild libcurl API: https://curl.se/libcurl/c/
 */
@interface SwiftyCurl : NSObject

/**
 HTTP server authentication methods to try.

 See https://curl.se/libcurl/c/CURLOPT_HTTPAUTH.html
 */
typedef NS_ENUM(NSUInteger, SwiftyCurlAuthMethods) {
    /**
     HTTP Basic authentication. This is the default choice, and the only method that is in
     wide-spread use and supported virtually everywhere.
     This sends the username and password over the network in plain text, easily captured by others.
     */
    Basic,

    /**
     HTTP Digest authentication. Digest authentication is defined in [RFC 2617](https://www.ietf.org/rfc/rfc2617.txt)
     and is a more secure way to do authentication over public networks than the regular old-fashioned Basic method.
     */
    Digest,

    /**
     HTTP Digest authentication with an IE flavor. Digest authentication is defined in [RFC 2617](https://www.ietf.org/rfc/rfc2617.txt)
     and is a more secure way to do authentication over public networks than the regular old-fashioned Basic method.

     The IE flavor is simply that libcurl uses a special "quirk" that IE is known to have used before version 7 and that some servers require the client to use.
     */
    DigestIe,

    /**
     HTTP Bearer token authentication, used primarily in OAuth 2.0 protocol.

     You can set the Bearer token to use with  ``SwiftyCurl.bearerToken``.
     */
    Bearer,

    /**
     HTTP NTLM authentication. A proprietary protocol invented and used by Microsoft.
     It uses a challenge-response and hash concept similar to Digest, to prevent the password from being eavesdropped.
     */
    Ntlm,

    /**
     This is a convenience macro that sets all bits and thus makes libcurl pick any it finds suitable.
     libcurl automatically selects the one it finds most secure.
     */
    Any,

    /**
     This is a convenience macro that sets all bits except Basic and thus makes libcurl pick any it finds suitable.
     libcurl automatically selects the one it finds most secure.
     */
    AnySafe,
};


/**
 Returns a human-readable string describing the libcurl version, its built-in dependencies, its supported protocols and its supported features.
 */
@property (readonly, class) NSString *libcurlVersion;

/**
 The dispatch queue to put curl requests on. Defaults to the global queue `QOS_CLASS_USER_INITIATED`.
 */
@property dispatch_queue_t queue;

/**
 Delegate to set on created `SCTask` objects.

 You can instead set this yourself per-task, too.
 */
@property (nullable, weak) NSObject<SCTaskDelegate> *delegate;

/**
 Set the allowed protocols for curl to avoid accidental execution of user-controlled requests.

 Defaults to "HTTP,HTTPS".

 NOTE: You can change this to other protocols, but the response processing is pretty much tailored to HTTP currently. Send merge requests!

 See https://curl.se/libcurl/c/CURLOPT_PROTOCOLS_STR.html
 */
@property NSString *allowedProtocols;

/**
 When enabled, libcurl automatically sets the Referer: header field in HTTP requests to the full URL when it follows a Location: redirect to a new destination.

 Defaults to `false`.

 See https://curl.se/libcurl/c/CURLOPT_AUTOREFERER.html
 */
@property BOOL autoReferer;

/**
 Set to `true` tells the library to follow any Location: header redirects that an HTTP server sends in a 30x response.
 The Location: header can specify a relative or an absolute URL to follow.

 Defaults to `false`.

 See https://curl.se/libcurl/c/CURLOPT_FOLLOWLOCATION.html
 */
@property BOOL followLocation;

/**
 HTTP user-agent header

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_USERAGENT.html
 */
@property (nullable) NSString *userAgent;

/**
 The location of a file on disk which will be used as the Cookie jar.

 The cookie data can be in either the old Netscape / Mozilla cookie data format or just regular HTTP headers (Set-Cookie style) dumped to a file.

 Using this option also enables cookies for this session, so if you for example follow a redirect it makes matching cookies get sent accordingly.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_COOKIEFILE.html and https://curl.se/libcurl/c/CURLOPT_COOKIEJAR.html
 */
@property (nullable) NSURL *cookieJar;

/**
 Custom hostname to IP address resolves.

 This option effectively populates the DNS cache with entries for the host+port pair so redirects and everything that operates against the HOST+PORT instead use your provided ADDRESS.

 If the DNS cache already has an entry for the given host+port pair, the new entry overrides the former one.

 See https://curl.se/libcurl/c/CURLOPT_RESOLVE.html
 */
@property (nullable) NSArray<SCResolveEntry *> *resolve;

/**
 HTTP server authentication methods to try.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_HTTPAUTH.html
 */
@property SwiftyCurlAuthMethods authMethod;

/**
 Username to use in authentication.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_USERNAME.html
 */
@property (nullable) NSString *username;

/**
 Password to use in authentication.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_PASSWORD.html
 */
@property (nullable) NSString *password;

/**
 OAuth 2.0 access token.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_XOAUTH2_BEARER.html
 */
@property (nullable) NSString *bearerToken;

/**
 AWS V4 signature.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_AWS_SIGV4.html
 */
@property (nullable) NSString *awsSigV4;

/**
 ``URLSession``-compatible proxy dictionary.

 HTTP, HTTPS and SOCKS proxy configurations are supported:

 ```
 {
    kCFProxyTypeKey: kCFProxyTypeSOCKS,
    kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion4|kCFStreamSocketSOCKSVersion5,
    kCFStreamPropertySOCKSProxyHost: "127.0.0.1",
    kCFStreamPropertySOCKSProxyPort: 1080,
    kCFStreamPropertySOCKSUser: "nobody", # OPTIONAL
    kCFStreamPropertySOCKSPassword: "foobar", # OPTIONAL
 },
 {
    kCFProxyTypeKey: kCFProxyTypeHTTP,
    kCFStreamPropertyHTTPProxyHost: "127.0.0.1",
    kCFStreamPropertyHTTPProxyPort: 1080,
 },
 {
    kCFProxyTypeKey: kCFProxyTypeHTTPS,
    kCFStreamPropertyHTTPSProxyHost: "127.0.0.1",
    kCFStreamPropertyHTTPSProxyPort: 1080,
 },
 ```

 For SOCKS proxies, curl supports 2 variants: One, where curl resolves hostnames, one where the SOCKS proxy resolves hostnames.

 @see [socksProxyResolves] to control that behaviour.

 See:
 - https://curl.se/libcurl/c/CURLOPT_PROXYTYPE.html
 - https://curl.se/libcurl/c/CURLOPT_PROXY.html
 - https://curl.se/libcurl/c/CURLOPT_PROXYPORT.html
 - https://curl.se/libcurl/c/CURLOPT_PROXYUSERNAME.html
 - https://curl.se/libcurl/c/CURLOPT_PROXYPASSWORD.html
 - https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411499-connectionproxydictionary?language=objc
 - https://developer.apple.com/documentation/cfnetwork
 -
 */
@property (nullable) NSDictionary *proxyDict;

/**
 Set this to `true`, if you want to have curl let the SOCKS proxy resolve hostnames.

 This is useful, if you're working with a proxy, which doesn't have UDP support for regular DNS.

 But the `resolve` property will become useless, then.

 @see [resolve]
 */
@property BOOL socksProxyResolves;

/**
 Verbose mode. Only honored when project is compiled in DEBUG mode.

 Defaults to `false`.

 See https://curl.se/libcurl/c/CURLOPT_VERBOSE.html
 */
@property BOOL verbose;


/**
 Initializes curl.

 It is not recommended to keep around more than one instance of this, as `curl_global_init` will be called here and `curl_global_cleanup` on deallocation.

 See https://curl.se/libcurl/c/curl_global_init.html and https://curl.se/libcurl/c/curl_global_cleanup.html
 */
- (instancetype)init;

/**
 Perform a GET request to a given URL asynchronously.

 @param url The URL to send a GET request to.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a ``NSHTTPURLResponse`` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithURL:(nonnull NSURL *)url completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a given request asynchronously.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a ``NSHTTPURLResponse`` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a GET request to a given URL asynchronously.

 @param url The URL to send a GET request to.

 @param progress Progress object which will report progress and which can be used to cancel the request.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a ``NSHTTPURLResponse`` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithURL:(nonnull NSURL *)url progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a given request asynchronously.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @param progress Progress object which will report progress and which can be used to cancel the request.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a ``NSHTTPURLResponse`` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithRequest:(nonnull NSURLRequest *)request progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Create a task with the given URL.

 @param url The URL to send a GET request to.

 @returns A prepared ``SCTask`` object you will need to ``resume`` to actually perform the request.
 */
- (nullable SCTask *)taskWithURL:(nonnull NSURL *)url;

/**
 Create a task with the given request.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @returns A prepared ``SCTask`` object you will need to ``resume`` to actually perform the request.
 */
- (nullable SCTask *)taskWithRequest:(nonnull NSURLRequest *)request;

/**
 Create a task with the given request.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @param progress An optional ``NSProgress`` object where the progress will be reported on. OPTIONAL. Will be created if `nil` and made available on the ``SCTask`` object.

 @returns A prepared ``SCTask`` object you will need to ``resume`` to actually perform the request.
 */
- (nullable SCTask *)taskWithRequest:(nonnull NSURLRequest *)request progress:(nullable NSProgress *)progress;

/**
 Helper function to fetch the user-agent string which `WKWebView` would use.

 @param completionHandler Callback, when user-agent is received.
    -  `userAgent`: User-Agent header used by `WKWebView`.
 */
+ (void)defaultUserAgent:(void (^)(NSString  * _Nullable userAgent))completionHandler;

@end

NS_ASSUME_NONNULL_END
