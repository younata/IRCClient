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

#import "IRCNumericReplies.h"

#import "RBScriptingService.h"

@implementation RBIRCChannel

-(instancetype)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        _log = [[NSMutableArray alloc] init];
        _names = [[NSMutableArray alloc] init];
        self.askedForNames = YES;
        self.connectOnStartup = YES;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]) != nil) {
        _name = [decoder decodeObjectForKey:@"name"];
        _log = [[NSMutableArray alloc] init];
        _names = [[NSMutableArray alloc] init];
        
        self.server = nil;
        self.topic = nil;
        self.connectOnStartup = [decoder decodeBoolForKey:@"connectOnStartup"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeBool:self.connectOnStartup forKey:@"connectOnStartup"];
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
    } else if (message.command == IRCMessageTypeNames) {
        if (self.askedForNames) {
            [self.names removeAllObjects];
            self.askedForNames = NO;
        }
        [self.names addObjectsFromArray:message.extra];
    } else if (message.commandNumber == RPL_ENDOFNAMES) {
        self.askedForNames = YES;
    }
    
    if (!(message.command == IRCMessageTypeJoin ||
          message.command == IRCMessageTypePart ||
          message.command == IRCMessageTypeNick ||
          message.command == IRCMessageTypeNames ||
          message.commandNumber == RPL_ENDOFNAMES ||
          message == nil)) {
        [_log addObject:message];
    }
    
    [[RBScriptingService sharedInstance] channel:self didLogMessage:message];
}

-(BOOL)isChannel
{
    return [self.name hasPrefix:@"#"] || [self.name hasPrefix:@"&"];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: connect: %@", self.name, self.connectOnStartup ? @"YES" : @"NO"];
}

@end
