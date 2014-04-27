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

#import <AFNetworking/AFNetworking.h>

#import "IRCNumericReplies.h"

@interface RBIRCMessage ()
{
    NSAttributedString *_attributedMessage;
}

@end

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
        case IRCMessageTypeCTCPErrMsg:
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

-(instancetype)initWithRawMessage:(NSString *)raw onServer:(id)server
{
    if ((self = [super init]) != nil) {
        self.server = server;
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
    
    NSString *str = nil;
    switch (self.command) {
        case IRCMessageTypeJoin:
            str = [NSString stringWithFormat:@"%@ joined", self.from];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:str attributes:[self defaultAttributes]];
            break;
        case IRCMessageTypePart:
            self.message = trailing;
            str = [NSString stringWithFormat:@"%@ left [%@]", self.from, trailing];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:str attributes:[self defaultAttributes]];
            break;
        case IRCMessageTypeNotice:
            self.message = trailing;
            [self parseCTCPResponse];
            [self loadImages];
            self.message = [NSString stringWithFormat:@"%@: %@", self.from, trailing];
            break;
        case IRCMessageTypePrivmsg:
            self.message = trailing;
            [self parseCTCPRequest];
            [self loadImages];
            self.message = [NSString stringWithFormat:@"%@: %@", self.from, trailing];
            break;
        case IRCMessageTypeMode: {
            NSMutableArray *modes = [[NSMutableArray alloc] init];
            if (params.count == 1) {
                [params addObject:trailing]; // fucking unrealircd...
            }
            self.message = [NSString stringWithFormat:@"MODE %@ %@", params[params.count - 2], params.lastObject]; // yeah, yeah...
            self.attributedMessage = [[NSAttributedString alloc] initWithString:self.message attributes:[self defaultAttributes]];
            
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
            str = [NSString stringWithFormat:@"%@ was kicked from %@ by %@ [%@]", params[1], self.targets[0], self.from, trailing];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:str attributes:[self defaultAttributes]];
            break;
        case IRCMessageTypeTopic:
            self.message = [params componentsJoinedByString:@" "];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:self.message attributes:[self defaultAttributes]];
            break;
        case IRCMessageTypeOper: // shouldn't have to handle
            break;
        case IRCMessageTypeNick:
            self.message = [NSString stringWithFormat:@"%@ is now known as %@", self.from, trailing]; // hopcount is server...
            self.extra = trailing;
            break;
        case IRCMessageTypeQuit:
            self.message = originalParamsString;
            str = [NSString stringWithFormat:@"%@ has quit [%@]", self.from, self.message];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:str attributes:[self defaultAttributes]];
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
    
    if (self.commandNumber != 0) {
        [self parseNumberedCommand:trailing withParams:params];
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
            NSString *message = [NSString stringWithFormat:@"* %@ %@", self.from, contents];
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
            NSString *message = [NSString stringWithFormat:@"* %@ %@", self.from, contents];
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

-(void)parseNumberedCommand:(NSString *)trailing withParams:(NSArray *)params
{
    switch (self.commandNumber) {
        case RPL_TOPIC: {// topic
            self.command = IRCMessageTypeTopic;
            self.targets = [@[self.message] mutableCopy];
            self.from = self.targets.firstObject;
            self.message = trailing;
            NSString *msg = [NSString stringWithFormat:@"Topic for %@, is %@", self.targets.firstObject, self.message];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:msg attributes:self.defaultAttributes];
            break;
        }
        case RPL_TOPICSETTER: {
            self.targets = [@[params[1]] mutableCopy];
            NSInteger ut = [params[3] integerValue];
            NSDate *then = [NSDate dateWithTimeIntervalSince1970:ut];
            self.message = [NSString stringWithFormat:@"Topic set by %@ on %@", params[2], [then descriptionWithLocale:[NSLocale currentLocale]]];
            self.attributedMessage = [[NSAttributedString alloc] initWithString:self.message attributes:self.defaultAttributes];
            break;
        }
        case RPL_NAMREPLY: // part of names
            self.command = IRCMessageTypeNames;
            self.targets = [@[params.lastObject] mutableCopy];
            self.extra = [trailing componentsSeparatedByString:@" "];
            self.from = self.targets.firstObject;
            break;
        case RPL_ENDOFNAMES: // end of names
            self.targets = [@[self.message] mutableCopy];
            self.message = trailing;
            break;
        default:
            break;
    }
}

-(void)loadImages
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:RBConfigLoadImages]) {
        return;
    }
    NSString *message = [self.message lowercaseString];
    if (![message containsSubstring:@"nsfw"] ||
        [[NSUserDefaults standardUserDefaults] boolForKey:RBConfigDontLoadNSFW]) {
        NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedMessage]];
        NSArray *matches = [[NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil] matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        for (id match in matches) {
            // load image
            NSURL *imageLocation = [match URL];
            NSString *img = [imageLocation absoluteString];
            if ([img hasSuffix:@".png"] ||
                [img hasSuffix:@".jpg"] ||
                [img hasSuffix:@".jpeg"] ||
                [img hasSuffix:@".tif"] ||
                [img hasSuffix:@".tiff"] ||
                [img hasSuffix:@".gif"] ||
                [img hasSuffix:@".bmp"] ||
                [img hasSuffix:@".bmpf"] ||
                [img hasSuffix:@".ico"] ||
                [img hasSuffix:@".cur"] ||
                [img hasSuffix:@".xbm"]) {
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"image/gif", @"image/jpeg", @"image/png", @"image/tiff", @"image/bmp", @"image/ico", nil];
                __weak RBIRCMessage *theSelf = self;
                [manager GET:img parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"Recieved image: %@", responseObject);
                    if ([responseObject isKindOfClass:[UIImage class]]) {
                        UIImage *image = (UIImage *)responseObject;
                        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
                        [attach setImage:image];
                        [mas appendAttributedString:[NSAttributedString attributedStringWithAttachment:attach]];
                        [(RBIRCServer *)theSelf.server sendUpdateMessageCommand:theSelf];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Error attempting to retrieve image: %@", error);
                }];
            }
        }
        self.attributedMessage = mas;
    }
}

-(NSString *)description
{
    if (self.command == IRCMessageTypePrivmsg || self.command == IRCMessageTypeNotice) {
        return [NSString stringWithFormat:@"%@: %@", self.from, self.message];
    }
    return self.message;
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

-(void)setAttributedMessage:(NSAttributedString *)attributedMessage
{
    _attributedMessage = attributedMessage;
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
    NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigFontName];
    if (!fontName) {
        fontName = @"Inconsolata";
        [[NSUserDefaults standardUserDefaults] setObject:fontName forKey:RBConfigFontName];
    }
    double fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey:RBConfigFontSize];
    if (fontSize == 0) {
        fontSize = 14.0;
        [[NSUserDefaults standardUserDefaults] setDouble:fontSize forKey:RBConfigFontSize];
    }
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
    if (!font) {
        font = [UIFont systemFontOfSize:fontSize];
    }
    return @{NSFontAttributeName:font};
}

@end
