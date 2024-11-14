//
//  SCConfig.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import <Foundation/Foundation.h>
#import "SCResolveEntry.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CurlConfig)
@interface SCConfig : NSObject

@property NSUInteger ticket;
@property NSProgress *progress;
@property NSURLRequest *request;


@property dispatch_queue_t queue;
@property NSString *allowedProtocols;
@property BOOL autoReferer;
@property BOOL followLocation;
@property (nullable) NSString *userAgent;
@property (nullable) NSURL *cookieJar;
@property (nullable) NSArray<SCResolveEntry *> *resolve;
@property long authMethod;
@property (nullable) NSString *username;
@property (nullable) NSString *password;
@property (nullable) NSString *bearerToken;
@property (nullable) NSString *awsSigV4;
@property (nullable) NSDictionary *proxyDict;
@property BOOL socksProxyResolves;
@property BOOL verbose;

@end

NS_ASSUME_NONNULL_END
