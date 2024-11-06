//
//  SCResolveEntry.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 05.11.24.
//

#import "SCResolveEntry.h"

@implementation SCResolveEntry

- (nonnull instancetype)initWith:(nonnull NSString *)host port:(NSUInteger)port addresses:(nonnull NSArray<NSString *> *)addresses
{
    self = [super init];

    if (self)
    {
        self.host = host;
        self.port = port;
        self.addresses = addresses;
    }

    return self;
}

- (nonnull instancetype)initWithURL:(NSURL * _Nonnull)url addresses:(NSArray<NSString *> * _Nonnull)addresses {
    NSUInteger port = 443;

    if (url.port > 0)
    {
        port = url.port.unsignedIntegerValue;
    }
    else if ([url.scheme.lowercaseString isEqualToString:@"https"])
    {
        port = 443;
    }
    else if ([url.scheme.lowercaseString isEqualToString:@"http"])
    {
        port = 80;
    }

    return [self initWith:url.host port:port addresses:addresses];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@%@:%lu:%@",
            self.timeout ? @"+" : @"",
            self.host,
            (unsigned long)self.port,
            [self.addresses componentsJoinedByString:@","]];
}

@end
