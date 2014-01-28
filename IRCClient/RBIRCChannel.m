//
//  RBIRCChannel.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCChannel.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

@implementation RBIRCChannel

-(instancetype)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        _log = [[NSMutableArray alloc] init];
        _names = [[NSMutableArray alloc] init];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[RBIRCChannel class]] && [[object name] isEqualToString:_name]);
}

-(void)logMessage:(RBIRCMessage *)message
{
    if (message.command == IRCMessageTypeTopic) {
        self.topic = message.message;
    } else if (message.command == IRCMessageTypeJoin) {
        if ([message.from isEqualToString:self.server.nick]) {
            // execute a /names command.
        } else {
            [self.names addObject:message.from];
        }
    } else if (message.command == IRCMessageTypePart) {
        if ([message.from isEqualToString:self.server.nick]) {
            // should not have recieved this.
            NSLog(@"Error: Recieved a self part");
        } else {
            [self.names removeObject:message.from];
        }
    }
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

-(NSString *)description
{
    return [NSString stringWithFormat:@"Channel '%@' on server '%@'", self.name, self.server.serverName];
}

@end
