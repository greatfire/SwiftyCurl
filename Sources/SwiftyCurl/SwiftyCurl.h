//
//  SwiftyCurl.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 25.10.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A nice abstraction over the wild libcurl API: https://curl.se/libcurl/c/
 */
@interface SwiftyCurl : NSObject

typedef NS_ENUM(NSUInteger, SwiftyCurlAuthMethods) {
    Basic,
    Digest,
    DigestIe,
    Bearer,
    Negotiate,
    Ntlm,
    Any,
    AnySafe,
};

/**
 @param data Received response data. Might be `nil` if server returned no response body or an error happened.

 @param response Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.

 @param error Any error happening during the request. Will be `nil` if a response was received.
 */
typedef void (^CompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);


/**
 The dispatch queue to put curl requests on. Defaults to the global queue `QOS_CLASS_USER_INITIATED`.
 */
@property dispatch_queue_t queue;

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
 The location of a file on disk which will be used as the Cookie jar.

 The cookie data can be in either the old Netscape / Mozilla cookie data format or just regular HTTP headers (Set-Cookie style) dumped to a file.

 Using this option also enables cookies for this session, so if you for example follow a redirect it makes matching cookies get sent accordingly.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_COOKIEFILE.html and https://curl.se/libcurl/c/CURLOPT_COOKIEJAR.html
 */
@property NSURL *cookieJar;

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
@property NSString *username;

/**
 Password to use in authentication.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_PASSWORD.html
 */
@property NSString *password;

/**
 OAuth 2.0 access token.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_XOAUTH2_BEARER.html
 */
@property NSString *bearerToken;

/**
 AWS V4 signature.

 Defaults to `nil`.

 See https://curl.se/libcurl/c/CURLOPT_AWS_SIGV4.html
 */
@property NSString *awsSigV4;

/**
 Verbose mode. Only honored when project is compiled i DEBUG mode.

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
     - `response`: Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithURL:(NSURL *)url completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a given request asynchronously.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithRequest:(NSURLRequest *)request completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a GET request to a given URL asynchronously.

 @param url The URL to send a GET request to.

 @param progress Progress object which will report progress and which can be used to cancel the request.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithURL:(NSURL *)url progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

/**
 Perform a given request asynchronously.

 @param request The request to send. URL, method, headers, body and timeout properties will be honored.

 @param progress Progress object which will report progress and which can be used to cancel the request.

 @param completionHandler Callback, when response is received:
     - `data`: Received response data. Might be `nil` if server returned no response body or an error happened.
     - `response`: Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.
     - `error`: Any error happening during the request. Will be `nil` if a response was received.
 */
- (void)performWithRequest:(NSURLRequest *)request progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
