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

typedef void (^CompletionHandler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);


@property dispatch_queue_t queue;
@property NSString *allowedProtocols;
@property BOOL autoReferer;
@property BOOL followLocation;
@property NSURL *cookieJar;
@property SwiftyCurlAuthMethods authMethod;
@property NSString *username;
@property NSString *password;
@property NSString *bearerToken;
@property NSString *awsSigV4;
@property BOOL verbose;


- (instancetype)init;

- (void)performWithURL:(NSURL *)url completionHandler:(nonnull CompletionHandler)completionHandler;

- (void)performWithRequest:(NSURLRequest *)request completionHandler:(nonnull CompletionHandler)completionHandler;

- (void)performWithURL:(NSURL *)url progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

- (void)performWithRequest:(NSURLRequest *)request progress:(nullable NSProgress *)progress completionHandler:(nonnull CompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
