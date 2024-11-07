//
//  SCTask-Private.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import <Foundation/Foundation.h>
#import "SCConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCTask (Private)

- (nullable instancetype)initWith:(nonnull SCConfig *)conf;

@end


NS_ASSUME_NONNULL_END
