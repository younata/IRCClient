//
//  RBIRCMessage.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCMessage.h"

@implementation RBIRCMessage

-(instancetype)initWithRawMessage:(NSString *)raw
{
    if ((self = [super init]) != nil) {
        _rawMessage = raw;
        _timestamp = [NSDate date];
        [self parseRawMessage];
    }
    return self;
}

-(void)parseRawMessage
{
    NSArray *array = [_rawMessage componentsSeparatedByString:@" "];
    NSArray *userAndHost = [[array[0] substringFromIndex:1] componentsSeparatedByString:@"!"];
    _from = userAndHost[0];
    _command = array[1];
    _to = array[2];
    NSString *msg = [array[3] substringFromIndex:1];
    for (int i = 4; i < [array count]; i++) {
        msg = [[msg stringByAppendingString:@" "] stringByAppendingString:array[i]];
    }
    _message = msg;
}

@end
