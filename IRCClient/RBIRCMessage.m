//
//  RBIRCMessage.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCMessage.h"

@implementation RBIRCMessage

+(NSString *)getMessageStringForType:(IRCMessageType)messagetype
{
    switch (messagetype) {
        case IRCMessageTypeJoin:
            return @"JOIN";
        case IRCMessageTypePart:
            return @"PART";
        case IRCMessageTypePrivmsg:
            return @"PRIVMSG";
        case IRCMessageTypeNotice:
            return @"NOTICE";
        case IRCMessageTypeMode:
            return @"MODE";
        case IRCMessageTypeKick:
            return @"KICK";
        case IRCMessageTypeTopic:
            return @"TOPIC";
        case IRCMessageTypeOper:
            return @"OPER";
        case IRCMessageTypeNick:
            return @"NICK";
        case IRCMessageTypeQuit:
            return @"QUIT";
        case IRCMessageTypeUnknown:
            return @"";
    }
    return nil;
}

+(IRCMessageType)getMessageTypeForString:(NSString *)messageString
{
    messageString = [messageString lowercaseString];
    NSDictionary *messageTypes = @{@"join": @(IRCMessageTypeJoin),
                                   @"part": @(IRCMessageTypePart),
                                   @"privmsg": @(IRCMessageTypePrivmsg),
                                   @"notice": @(IRCMessageTypeNotice),
                                   @"mode": @(IRCMessageTypeMode),
                                   @"kick": @(IRCMessageTypeKick),
                                   @"topic": @(IRCMessageTypeTopic),
                                   @"oper": @(IRCMessageTypeOper),
                                   @"nick": @(IRCMessageTypeNick),
                                   @"quit": @(IRCMessageTypeQuit)
                                   };
    if ([[messageTypes allKeys] containsObject:messageString]) {
        return [messageTypes[messageString] intValue];
    }
    return IRCMessageTypeUnknown;
}

-(instancetype)initWithRawMessage:(NSString *)raw
{
    if ((self = [super init]) != nil) {
        raw = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.rawMessage = raw;
        self.timestamp = [NSDate date];
        [self parseRawMessage];
    }
    return self;
}

-(void)parseRawMessage
{
    NSArray *array = [self.rawMessage componentsSeparatedByString:@" "];
    NSArray *userAndHost = [[array[0] substringFromIndex:1] componentsSeparatedByString:@"!"];
    self.from = userAndHost[0];
    self.command = [RBIRCMessage getMessageTypeForString:array[1]];
    self.to = array[2];
    if ([array count] == 3) {
        if ([self.to hasPrefix:@":"]) {
            self.to = [self.to substringFromIndex:1];
        }
        self.message = nil;
        return;
    }
    NSString *msg = array[3];
    if ([msg hasPrefix:@":"]) {
        msg = [msg substringFromIndex:1];
    }
    for (int i = 4; i < [array count]; i++) {
        msg = [[msg stringByAppendingString:@" "] stringByAppendingString:array[i]];
    }
    self.message = msg;
    if (self.command == IRCMessageTypeMode) {
        self.extra = [self.message componentsSeparatedByString:@" "];
    } else if (self.command == IRCMessageTypeKick) {
        NSArray *arr = [self.message componentsSeparatedByString:@" "];
        self.extra = @{@"target": arr[0], @"reason": [arr[1] substringFromIndex:1]};
    }
}

-(NSString *)description
{
    NSString *ret = @"";
    if (!self.from)
        return self.rawMessage;
    ret = [NSString stringWithFormat:@"%@: %@", self.from, self.message];
    return ret;
}

-(NSString *)debugDescription
{
    NSString *ret = @"";
    
    ret = [NSString stringWithFormat:@"from: %@\nto: %@\ncommand: %@\nmessage: %@", self.from, self.to, [RBIRCMessage getMessageStringForType:self.command], self.message];
    
    return ret;
}

@end
