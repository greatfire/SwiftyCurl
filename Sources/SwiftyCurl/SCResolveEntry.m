//
//  SCResolveEntry.m
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 05.11.24.
//

#import "SCResolveEntry.h"

@implementation SCResolveEntry

- (nonnull instancetype)initWith:(NSString * _Nonnull)host port:(NSUInteger)port
{
    return [self initWith:host port:port addresses:@[]];
}

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

- (nonnull instancetype)initWithURL:(NSURL * _Nonnull)url
{
    return [self initWithURL:url addresses:@[]];
}

- (nonnull instancetype)initWithURL:(NSURL * _Nonnull)url addresses:(NSArray<NSString *> * _Nonnull)addresses {
    NSUInteger port = 443;

    if (url.port > 0)
    {
        port = url.port.unsignedIntegerValue;
    }
    else if ([url.scheme.lowercaseString isEqualToString:@"http"])
    {
        port = 80;
    }

    return [self initWith:url.host port:port addresses:addresses];
}


- (NSString *)description
{
    if (self.addresses.count > 0)
    {
        return [NSString stringWithFormat:@"%@%@:%lu:%@",
                self.timeout ? @"+" : @"",
                self.host,
                (unsigned long)self.port,
                [self.addresses componentsJoinedByString:@","]];
    }
    else {
        return [NSString stringWithFormat:@"-%@:%lu",
                self.host,
                (unsigned long)self.port];
    }
}

- (BOOL)isEqualToResolveEntry:(SCResolveEntry * _Nullable)other
{
    return self.port == other.port
        && [self.host isEqualToString:other.host];
}

- (BOOL)isEqual:(id)other
{
    if (other == nil)
    {
        return NO;
    }

    if (self == other)
    {
        return YES;
    }

    if (![other isKindOfClass:SCResolveEntry.class])
    {
        return NO;
    }

    return [self isEqualToResolveEntry:other];
}

- (NSUInteger)hash
{
    return self.port ^ self.host.hash;
}

@end
