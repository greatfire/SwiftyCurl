//
//  SCProgress.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 31.10.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CurlProgress)
@interface SCProgress : NSObject

@property NSProgress *progress;
@property int64_t dltotal;
@property int64_t dlnow;
@property int64_t ultotal;
@property int64_t ulnow;

@property (readonly) BOOL cancelled;


- (instancetype)initWith:(NSProgress *)progress;

- (void)applyUlTotal:(int64_t)ultotal ulNow:(int64_t)ulnow dlTotal:(int64_t)dltotal dlNow:(int64_t)dlnow;

@end

NS_ASSUME_NONNULL_END
