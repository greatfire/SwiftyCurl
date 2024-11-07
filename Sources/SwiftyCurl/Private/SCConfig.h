//
//  SCConfig.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import <Foundation/Foundation.h>
#import "SCResolveEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCConfig : NSObject

@property NSUInteger ticket;
@property NSProgress *progress;
@property NSURLRequest *request;


@property dispatch_queue_t queue;
@property NSString *allowedProtocols;
@property BOOL autoReferer;
@property BOOL followLocation;
@property NSURL *cookieJar;
@property NSArray<SCResolveEntry *> *resolve;
@property long authMethod;
@property NSString *username;
@property NSString *password;
@property NSString *bearerToken;
@property NSString *awsSigV4;
@property BOOL verbose;

@end

NS_ASSUME_NONNULL_END