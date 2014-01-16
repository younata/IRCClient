//
//  RBIRCChannel.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCChannel.h"

@implementation RBIRCChannel

-(instancetype)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        _log = [[NSMutableArray alloc] init];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[RBIRCChannel class]] && [[object name] isEqualToString:_name]);
}

-(void)logMessage:(RBIRCMessage *)message
{
    [_log addObject:message];
}

@end
