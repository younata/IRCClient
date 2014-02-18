//
//  RBIRCMessage.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCMessage.h"
#import "NSString+contains.h"
#import "RBIRCServer.h" // just for RBIRCServerLog...

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
        case IRCMessageTypePing:
            return @"PING";
        case IRCMessageTypeNames:
            return @"NAMES";
        case IRCMessageTypeInvite:
            return @"INVITE";
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
                                   @"quit": @(IRCMessageTypeQuit),
                                   @"ping": @(IRCMessageTypePing),
                                   @"invite": @(IRCMessageTypeInvite),
                                   @"names": @(IRCMessageTypeNames)
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
        self.commandNumber = -1;
        [self parseRawMessage];
        [self attributedMessage];
    }
    return self;
}

-(void)parseRawMessage
{
    NSArray *array = [self.rawMessage componentsSeparatedByString:@" "];
    NSString *name = nil;
    NSString *user = nil;
    NSString *host = nil;
    NSInteger idx = 0;
    NSInteger location;
    if ([self.rawMessage hasPrefix:@":"]) {
        NSString *prefixString = [array[0] substringFromIndex:1];
        if (![prefixString containsSubstring:@"!"] && ![prefixString containsSubstring:@"@"]) {
            name = prefixString;
        } else if ([prefixString containsSubstring:@"!"] && ![prefixString containsSubstring:@"@"]) {
            location = [prefixString rangeOfString:@"!"].location;
            name = [prefixString substringToIndex:location];
            user = [prefixString substringFromIndex:location+1];
        } else if (![prefixString containsSubstring:@"!"] && [prefixString containsSubstring:@"@"]) {
            location = [prefixString rangeOfString:@"@"].location;
            name = [prefixString substringToIndex:location];
            host = [prefixString substringFromIndex:location+1];
        } else {
            location = [prefixString rangeOfString:@"!"].location;
            name = [prefixString substringToIndex:location];
            location++;
            NSInteger location2 = [prefixString rangeOfString:@"@"].location;
            NSRange range = NSMakeRange(location, location2 - location);
            user = [prefixString substringWithRange:range];
            host = [prefixString substringFromIndex:location2+1];
        }
        idx++;
    }
    self.from = name;
    NSString *command = array[idx];
    idx++;
    if ([command integerValue] == 0) {
        self.command = [RBIRCMessage getMessageTypeForString:command];
    } else {
        self.command = IRCMessageTypeUnknown;
        self.commandNumber = [command integerValue];
    }
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    
    NSString *paramsString = [[[array subarrayWithRange:NSMakeRange(idx, array.count - idx)] componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *originalParamsString = paramsString;
    
    NSString *trailing = nil;
    while (![paramsString hasPrefix:@":"]) {
        location = [paramsString rangeOfString:@" "].location;
        if (![paramsString containsSubstring:@" "]) {
            [params addObject:paramsString];
            break;
        }
        [params addObject:[paramsString substringToIndex:location]];
        paramsString = [paramsString substringFromIndex:location+1];
    }
    
    trailing = [paramsString substringFromIndex:1];
    
    if (params.count != 0) {
        self.targets = [[params[0] componentsSeparatedByString:@","] mutableCopy];
        self.message = [[params subarrayWithRange:NSMakeRange(1, params.count - 1)] componentsJoinedByString:@" "];
    }
    
    switch (self.command) {
        case IRCMessageTypeJoin:
            break;
        case IRCMessageTypePart:
            self.message = trailing;
            break;
        case IRCMessageTypeNotice:
        case IRCMessageTypePrivmsg:
            self.message = trailing;
            break;
        case IRCMessageTypeMode: {
            NSMutableArray *modes = [[NSMutableArray alloc] init];
            if (params.count == 1) {
                [params addObject:trailing]; // fucking unrealircd...
                self.message = trailing;
            }
            int i = 1; // params[0] is targets...
            while ([params[i] hasPrefix:@"+"] || [params[i] hasPrefix:@"-"]) {
                [modes addObject:params[i]];
                i++;
                if (i == params.count)
                    break;
            }
            if ([self.targets[0] hasPrefix:@"#"] || [self.targets[0] hasPrefix:@"&"]) {
                self.extra = [@[modes] arrayByAddingObjectsFromArray:[params subarrayWithRange:NSMakeRange(i, params.count - i)]];
            } else {
                self.extra = @[modes];
            }
            break;
        }
        case IRCMessageTypeKick:
            self.extra = @{params[1]: trailing};
            self.message = [NSString stringWithFormat:@"%@ :%@", params[1], trailing];
            break;
        case IRCMessageTypeTopic:
            self.message = [params componentsJoinedByString:@" "];
            break;
        case IRCMessageTypeOper: // shouldn't have to handle
            break;
        case IRCMessageTypeNick:
            self.message = params[0]; // hopcount is server...
            break;
        case IRCMessageTypeQuit:
            self.message = originalParamsString;
            break;
        case IRCMessageTypePing:
            self.message = trailing;
            break;
        case IRCMessageTypeNames:
            break;
        case IRCMessageTypeInvite:
            break;
        case IRCMessageTypeUnknown:
            break;
    }
}

-(NSString *)description
{
    NSString *ret = @"";
    if (!self.from || [self.from isEqualToString:RBIRCServerLog])
        return self.rawMessage;
    ret = [NSString stringWithFormat:@"%@: %@", self.from, self.message];
    return ret;
}

-(NSString *)debugDescription
{
    NSString *ret = @"";
    
    ret = [NSString stringWithFormat:@"from: '%@'\nto: '%@'\ncommand: '%@'\nmessage: '%@'", self.from, self.targets, [RBIRCMessage getMessageStringForType:self.command], self.message];
    if (self.extra) {
        ret = [NSString stringWithFormat:@"%@\nextra: '%@'", ret, self.extra];
    }
    
    return ret;
}

-(NSAttributedString *)attributedMessage
{
    if (_attributedMessage) {
        _attributedMessage = [[NSAttributedString alloc] initWithString:[self description] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}];
    }
    
    return _attributedMessage;
}

@end
