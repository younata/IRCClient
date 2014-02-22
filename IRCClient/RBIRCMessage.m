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
#import "RBConfigurationKeys.h"
#import "UIDevice+Categories.h"

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
        case IRCMessageTypeCTCPFinger:
            return @"FINGER";
        case IRCMessageTypeCTCPVersion:
            return @"VERSION";
        case IRCMessageTypeCTCPSource:
            return @"SOURCE";
        case IRCMessageTypeCTCPUserInfo:
            return @"USERINFO";
        case IRCMessageTypeCTCPClientInfo:
            return @"CLIENTINFO";
        case IRCMessageTypeCTCPPing:
            return @"PING";
        case IRCMessageTypeCTCPTime:
            return @"TIME";
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
                                   @"names": @(IRCMessageTypeNames),
                                   @"finger": @(IRCMessageTypeCTCPFinger),
                                   @"version": @(IRCMessageTypeCTCPVersion),
                                   @"source": @(IRCMessageTypeCTCPSource),
                                   @"userinfo": @(IRCMessageTypeCTCPUserInfo),
                                   @"clientinfo": @(IRCMessageTypeCTCPClientInfo),
                                   @"ping": @(IRCMessageTypeCTCPPing),
                                   @"time": @(IRCMessageTypeCTCPTime)
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
            self.message = trailing;
            [self parseCTCPResponse];
            break;
        case IRCMessageTypePrivmsg:
            self.message = trailing;
            [self parseCTCPRequest];
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
        default:
            break;
    }
}

-(void)parseCTCPRequest // privmsg
{
    NSString *msg = self.message;
    NSString *delim = [NSString stringWithFormat:@"%c", 1];
    if ([msg characterAtIndex:0] != 1) {
        return; // not up to spec, but this passes my tests.
    }
    NSString *rest = [msg substringFromIndex:1];
    NSRange range = [rest rangeOfString:delim];
    rest = [rest substringWithRange:NSMakeRange(0, range.location)];
    IRCMessageType newCmd = [RBIRCMessage getMessageTypeForString:rest];
    if ([rest hasPrefix:@"PING"]) {
        newCmd = IRCMessageTypeCTCPPing;
    }
    if (newCmd == IRCMessageTypeUnknown) {
        if ([rest hasPrefix:@"ACTION"]) {
            NSString *contents = [rest substringFromIndex:7];
            NSString *message = [NSString stringWithFormat:@"%@ %@", self.from, contents];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:[self defaultAttributes]];
        } else {
            self.command = IRCMessageTypeCTCPErrMsg;
            self.extra = @"Unrecognized CTCP command";
        }
        return;
    }
    NSString *repl = nil;
    switch (newCmd) {
        case IRCMessageTypeCTCPFinger:
            repl = [[NSUserDefaults standardUserDefaults] objectForKey:RBCTCPFinger];
            if (repl) {
                self.extra = repl;
            } else {
                self.extra = @"Unknown";
            }
            self.extra = [@":" stringByAppendingString:self.extra];
            break;
        case IRCMessageTypeCTCPVersion: {
            repl = [[NSUserDefaults standardUserDefaults] objectForKey:RBCTCPVersion];
            if (repl) {
                self.extra = repl;
            } else {
                NSDictionary *info = [[NSBundle mainBundle] infoDictionary]; // I actually want this in english...
                NSString *appname = [info objectForKey:@"CFBundleDisplayName"];
                NSString *version = [info objectForKey:@"CFBundleShortVersionString"];
                NSString *build = [info objectForKey:@"CFBundleVersion"];
                UIDevice *cd = [UIDevice currentDevice];
                NSString *device = [NSString stringWithFormat:@"%@ %@ on an %@", cd.systemName, cd.systemVersion, cd.platformString];
                self.extra = [NSString stringWithFormat:@"%@ version %@ build %@ running on %@", appname, version, build, device];
            }
            break;
        } case IRCMessageTypeCTCPSource:
            self.extra = @"https://github.com/younata/IRCClient/";
            break;
        case IRCMessageTypeCTCPUserInfo:
            repl = [[NSUserDefaults standardUserDefaults] objectForKey:RBCTCPUserInfo];
            if (repl) {
                self.extra = repl;
            } else {
                self.extra = @"Unknown";
            }
            self.extra = [@":" stringByAppendingString:self.extra];
            break;
        case IRCMessageTypeCTCPClientInfo:
            self.extra = @"FINGER VERSION SOURCE USERINFO CLIENTINFO PING TIME";
            break;
        case IRCMessageTypeCTCPPing:
            self.extra = [rest substringFromIndex:5];
            break;
        case IRCMessageTypeCTCPTime: {
            NSDate *now = [NSDate date];
            self.extra = [now descriptionWithLocale:[NSLocale currentLocale]];
            break;
        } default:
            break;
    }
    self.command = newCmd;
}

-(void)parseCTCPResponse // notice
{
    NSString *msg = self.message;
    NSString *delim = [NSString stringWithFormat:@"%c", 1];
    if ([msg characterAtIndex:0] != 1) {
        return; // not up to spec, but this passes my tests.
    }
    NSString *rest = [msg substringFromIndex:1];
    NSRange range = [rest rangeOfString:delim];
    rest = [rest substringWithRange:NSMakeRange(0, range.location)];
    IRCMessageType newCmd = [RBIRCMessage getMessageTypeForString:rest];
    if ([rest hasPrefix:@"PING"]) {
        newCmd = IRCMessageTypeCTCPPing;
    }
    if (newCmd == IRCMessageTypeUnknown) {
        if ([rest hasPrefix:@"ACTION"]) {
            NSString *contents = [rest substringFromIndex:7];
            NSString *message = [NSString stringWithFormat:@"%@ %@", self.from, contents];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:[self defaultAttributes]];
        } else {
            self.command = IRCMessageTypeCTCPErrMsg;
            self.extra = @"Unrecognized CTCP command";
        }
        return;
    }
    NSString *repl = [rest substringFromIndex:[rest rangeOfString:@" "].location + 1];
    switch (newCmd) {
        case IRCMessageTypeCTCPFinger:
        case IRCMessageTypeCTCPUserInfo:
            repl = [repl substringFromIndex:1];
            break;
        case IRCMessageTypeCTCPVersion:
        case IRCMessageTypeCTCPSource:
        case IRCMessageTypeCTCPClientInfo:
        case IRCMessageTypeCTCPTime:
            break;
        case IRCMessageTypeCTCPPing: {
            double timestamp = [repl doubleValue];
            double now = [[NSDate date] timeIntervalSince1970];
            double difference = now - timestamp;
            repl = [NSString stringWithFormat:@"%f seconds", difference];
            break;
        }
        default:
            break;
    }
    NSString *str = [NSString stringWithFormat:@"CTCP %@ reply: %@", [[RBIRCMessage getMessageStringForType:newCmd] capitalizedString], repl];
    self.attributedMessage = [[NSAttributedString alloc] initWithString:str attributes:[self defaultAttributes]];
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
    if (!_attributedMessage) {
        _attributedMessage = [[NSAttributedString alloc] initWithString:[self description] attributes:[self defaultAttributes]];
    }
    
    return _attributedMessage;
}

-(NSDictionary *)defaultAttributes
{
    return @{NSFontAttributeName:[UIFont systemFontOfSize:14]};
}

@end
