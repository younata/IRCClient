//
//  RBIRCChannel.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCChannel.h"
#import "RBIRCServer.h"

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

#pragma mark - Channel

-(void)join:(NSString *)pass
{
    NSString *cmd = [NSString stringWithFormat:@"JOIN %@", _name];
    if (pass) {
        cmd = [cmd stringByAppendingString:[NSString stringWithFormat:@" %@", pass]];
    }
    [_server sendCommand:cmd];
}

-(void)part:(NSString *)message
{
    [_server sendCommand:[NSString stringWithFormat:@"part %@ %@", _name, message]];
}

-(void)mode:(NSString *)options
{
    [_server sendCommand:[NSString stringWithFormat:@"mode %@ %@", _name, options]];
}

-(void)topic:(NSString *)topic
{
    [_server sendCommand:[NSString stringWithFormat:@"topic %@ %@", _name, topic]];
}

@end
