//
//  SCProgress.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 31.10.24.
//

#import "SCProgress.h"

@implementation SCProgress

- (instancetype)initWith:(NSProgress *)progress
{
    self = [super init];

    if (self)
    {
        self.progress = progress;
    }

    return self;
}

- (BOOL)cancelled
{
    return self.progress.cancelled;
}

- (void)applyUlTotal:(int64_t)ultotal ulNow:(int64_t)ulnow dlTotal:(int64_t)dltotal dlNow:(int64_t)dlnow
{
    // curl will report 0 ultotal and ulnow again when it starts downloading.
    // Hence, only store values, if they are greater than what we already have.

    if (ultotal > self.ultotal)
    {
        self.ultotal = ultotal;
    }

    if (ulnow > self.ulnow)
    {
        self.ulnow = ulnow;
    }

    if (self.ulnow > self.ultotal)
    {
        // We have uploaded more than total? That can't be right.
        self.ultotal = self.ulnow;
    }

    if (dltotal > self.dltotal)
    {
        self.dltotal = dltotal;
    }

    if (dlnow > self.dlnow)
    {
        self.dlnow = dlnow;
    }

    if (self.dlnow > self.dltotal)
    {
        // We have downloaded more than total? That can't be right.
        self.dltotal = self.dlnow;
    }

    self.progress.totalUnitCount = self.ultotal + self.dltotal;
    self.progress.completedUnitCount = self.ulnow + self.dlnow;
}



@end
