//
//  SCResolveEntry.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 05.11.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Data structure to ease creation of CURLOPT_RESOLVE entries.

 See https://curl.se/libcurl/c/CURLOPT_RESOLVE.html.
 */
@interface SCResolveEntry : NSObject

/**
 The name libcurl wants to resolve.

 Specify the host as a single ampersand (*) to match all names. This wildcard is resolved last so any resolve with a specific host and port number is given priority.
 */
@property NSString *host;

/**
 The port number of the service where libcurl wants to connect to.
 */
@property NSUInteger port;

/**
 One or more numerical IP addresses.

 If libcurl is built to support IPv6, each of the ADDRESS entries can of course be either IPv4 or IPv6 style addressing.
 */
@property NSArray<NSString *> *addresses;

/**
 Specify that the new entry should timeout. Entries with this flag set time out just like ordinary DNS cache entries.
 */
@property BOOL timeout;

- (instancetype)initWith:(NSString * _Nonnull)host port:(NSUInteger)port addresses:(NSArray<NSString *> * _Nonnull)addresses;

- (instancetype)initWithURL:(NSURL * _Nonnull)url addresses:(NSArray<NSString *> * _Nonnull)addresses;


@end

NS_ASSUME_NONNULL_END
