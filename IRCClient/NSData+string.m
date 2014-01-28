//
//  NSData+string.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/27/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "NSData+string.h"

@implementation NSData (string)

+(instancetype)dataWithString:(NSString *)string
{
    return [[NSData alloc] initWithBytes:[string UTF8String] length:[string length]];
}

@end
