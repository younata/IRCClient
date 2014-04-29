//
//  RBIRCServer.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "RBIRCChannel.h"
#import "NSStream+remoteHost.h"
#import "NSString+isNilOrEmpty.h"
#import "NSString+contains.h"

#import "RBScriptingService.h"

@interface RBIRCServer ()

@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableString *incompleteMessages;

@end

@implementation RBIRCServer

@synthesize readStream;
@synthesize writeStream;

@synthesize channels;
@synthesize nick;

-(instancetype)init
{
    if ((self = [super init])) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithHostname:(NSString *)hostname ssl:(BOOL)useSSL port:(NSString *)port nick:(NSString *)nickname realname:(NSString *)realname password:(NSString *)password
{
    if ((self = [super init]) != nil) {
        self.nick = nickname;
        self.hostname = hostname;
        self.port = port;
        self.useSSL = useSSL;
        self.realname = realname;
        self.password = password;
        
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]) != nil) {
        self.serverName = [decoder decodeObjectForKey:@"serverName"];
        self.nick = [decoder decodeObjectForKey:@"nickname"];
        self.hostname = [decoder decodeObjectForKey:@"hostname"];
        self.port = [decoder decodeObjectForKey:@"port"];
        self.useSSL = [decoder decodeBoolForKey:@"useSSL"];
        self.realname = [decoder decodeObjectForKey:@"realname"];
        self.password = [decoder decodeObjectForKey:@"password"];
        
        self.connectOnStartup = [decoder decodeBoolForKey:@"connectOnStartup"];
        channels = [decoder decodeObjectForKey:@"channels"];
        
        self.commandQueue = [[NSMutableArray alloc] init];
        
        self.incompleteMessages = [[NSMutableString alloc] init];
        
        [self createServerLog];
        
        if (self.connectOnStartup) {
            [self reconnect];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.serverName forKey:@"serverName"];
    [coder encodeObject:self.nick forKey:@"nickname"];
    [coder encodeObject:self.hostname forKey:@"hostname"];
    [coder encodeObject:self.port forKey:@"port"];
    [coder encodeBool:self.useSSL forKey:@"useSSL"];
    [coder encodeObject:self.realname forKey:@"realname"];
    [coder encodeObject:self.password forKey:@"password"];
    
    [coder encodeBool:self.connectOnStartup forKey:@"connectOnStartup"];
    NSMutableDictionary *channelsToSave = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.channels.allKeys) {
        RBIRCChannel *channel = self.channels[key];
        if (channel.isChannel && channel.connectOnStartup) {
            channelsToSave[key] = channel;
        }
    }
    [coder encodeObject:channelsToSave forKey:@"channels"];
}

-(void)reconnect
{
    [self connect];
    for (NSString *key in self.channels.allKeys) {
        if ([key isEqualToString:RBIRCServerLog]) {
            continue;
        }
        RBIRCChannel *channel = self.channels[key];
        if (channel.connectOnStartup && channel.isChannel) {
            NSString *s = [NSString stringWithFormat:@"join %@", key];
            if ([channel.password hasContent]) {
                s = [NSString stringWithFormat:@"%@ %@", s, channel.password];
            }
            s = [NSString stringWithFormat:@"%@\r\n", s];
            [self.commandQueue addObject:s];
        }
    }
}

-(BOOL)connected
{
    if (self.readStream == nil)
        return NO;
    return 1 <= self.readStream.streamStatus <= 4;
}

-(void)createServerLog
{
    RBIRCChannel *serverLog = [[RBIRCChannel alloc] initWithName:RBIRCServerLog];
    [channels setObject:serverLog forKey:RBIRCServerLog];
}

-(void)commonInit
{
    channels = [[NSMutableDictionary alloc] init];
    [self createServerLog];
    self.incompleteMessages = [[NSMutableString alloc] init];
    
    self.connectOnStartup = YES;
}

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[RBIRCServer class]])
        return NO;
    RBIRCServer *s = (RBIRCServer *)object;
    if ([self.serverName isEqualToString:s.serverName])
        if ([self.nick isEqualToString:s.nick])
            if ([self.hostname isEqualToString:s.hostname])
                if ([self.port isEqualToString:s.port])
                    if ([self.realname isEqualToString:s.realname])
                        if ([self.password isEqualToString:s.password])
                            if (self.useSSL == s.useSSL)
                                return YES;
    return NO;
}

-(void)sendCommand:(NSString *)command
{
    if (!self.connected) {
        return;
    }
    if (![command hasSuffix:[NSString stringWithFormat:@"\r\n"]]) {
        command = [command stringByAppendingString:@"\r\n"];
    }
    signed long numBytesWritten = [writeStream write:(const unsigned char *)[command UTF8String] maxLength:[command length]];
    if (numBytesWritten < 0) {
        NSError *error = [writeStream streamError];
        NSLog(@"Error Writing to stream: %@", error);
        [self.writeStream close];
        [self.readStream close];
    } else if (numBytesWritten == 0) {
        if ([writeStream streamStatus] == kCFStreamStatusAtEnd) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerConnectionDidDisconnect object:self userInfo:nil];
        }
    } else if (numBytesWritten != [command length]) {
        NSString *cmd = [command substringWithRange:NSMakeRange(numBytesWritten, [command length] - (2 + numBytesWritten))];
        [self sendCommand:cmd];
    }
}

-(void)connect
{
    [self connect:self.realname withPassword:self.password];
}

-(void)connect:(NSString *)realname
{
    [self connect:realname withPassword:nil];
}

-(void)connect:(NSString *)realname withPassword:(NSString *)pass
{
    if (self.connected)
        return;
    NSInputStream *is;
    NSOutputStream *os;
    [NSStream getStreamsToHost:self.hostname port:self.port inputStream:&is outputStream:&os];
    
    self.readStream = is;
    self.writeStream = os;
    
    [self.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if (self.useSSL) {
        NSDictionary *settings = @{(__bridge_transfer NSString *)kCFStreamSSLAllowsAnyRoot: @(YES),
                                   (__bridge_transfer NSString *)kCFStreamSSLAllowsExpiredCertificates: @(YES),
                                   (__bridge_transfer NSString *)kCFStreamSSLAllowsExpiredRoots: @(YES)};
        [self.readStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        [self.writeStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        CFReadStreamSetProperty((__bridge_retained CFReadStreamRef)self.readStream, kCFStreamPropertySSLSettings, (__bridge_retained CFDictionaryRef)settings);
        CFWriteStreamSetProperty((__bridge_retained CFWriteStreamRef)self.writeStream, kCFStreamPropertySSLSettings, (__bridge_retained CFDictionaryRef)settings);

    }
    
    [self.readStream setDelegate:self];
    [self.writeStream setDelegate:self];
    
    [self.writeStream open];
    [self.readStream open];
    
    RBIRCServer *theSelf = (RBIRCServer *)self;
    onConnect = ^{
        if ([pass hasContent]) {
            [theSelf sendCommand:[@"pass " stringByAppendingString:pass]];
        }
        [theSelf nick:theSelf.nick];
        [theSelf sendCommand:[NSString stringWithFormat:@"user %@ foo bar %@", theSelf.nick, realname]];
        [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerDidConnect object:theSelf userInfo:nil];
        if (theSelf.debugLock)
            [theSelf.debugLock unlock];
        
        [[RBScriptingService sharedInstance] serverDidConnect:theSelf];
    };
}

-(void)receivedString:(NSString *)str
{
    if ([str hasPrefix:@"ERROR"])
        return;
    RBIRCMessage *msg;
    @try {
        msg = [[RBIRCMessage alloc] initWithRawMessage:str onServer:self];
    }
    @catch (NSException *exception) {
        NSLog(@"error parsing message '%@'\nException: %@", str, exception); // I'm bad and I should feel bad.
        msg = nil;
    }
    if (!msg) {
        msg = [[RBIRCMessage alloc] init];
        msg.targets = [@[RBIRCServerLog] mutableCopy];
        msg.message = str;
        msg.rawMessage = str;
        msg.server = self;
    }
    if (msg.command == IRCMessageTypePing) {
        [self sendCommand:[NSString stringWithFormat:@"PONG %@", msg.message]];
        return;
    }
    
    NSArray *hostParts = [self.hostname componentsSeparatedByString:@"."];
    NSString *superDomain = self.hostname;
    if (hostParts.count > 2) {
        superDomain = [[hostParts subarrayWithRange:NSMakeRange(1, hostParts.count - 1)] componentsJoinedByString:@"."];
    }
    
    if (([msg.from containsSubstring:superDomain]) && (msg.commandNumber == 1)) {
        while (self.commandQueue.count > 0) {
            [self sendCommand:self.commandQueue.lastObject];
            [self.commandQueue removeLastObject];
        }
    }
    
    [[RBScriptingService sharedInstance] server:self didReceiveMessage:msg];
    
    RBIRCChannel *ch;
    for (int i = 0; i < msg.targets.count; i++) {
        NSString *to = msg.targets[i];
        if ([to isEqualToString:self.nick]) {
            to = msg.from;
        }
        if (msg.command == IRCMessageTypeNotice) {
            to = nil;
        }
        if (![to hasContent] || [to isEqualToString:@"*"] || [to isEqualToString:@"AUTH"] || [to containsSubstring:superDomain]) {
            ch = [channels objectForKey:RBIRCServerLog];
            msg.message = msg.rawMessage;
            to = RBIRCServerLog;
            msg.targets[i] = to;
        } else {
            if (channels[to] != nil) {
                ch = channels[to];
            } else {
                ch = [[RBIRCChannel alloc] initWithName:to];
                [channels setObject:ch forKey:to];
                ch.server = self;
            }
        }
        [ch logMessage:msg];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerHandleMessage object:self userInfo:@{@"message": msg}];
    
    switch (msg.command) {
        case IRCMessageTypeCTCPFinger:
        case IRCMessageTypeCTCPVersion:
        case IRCMessageTypeCTCPSource:
        case IRCMessageTypeCTCPUserInfo:
        case IRCMessageTypeCTCPClientInfo:
        case IRCMessageTypeCTCPPing:
        case IRCMessageTypeCTCPTime: {
            NSString *ret = [NSString stringWithFormat:@"NOTICE %@ :%c%@ %@%c\r\n", msg.from, 1, [RBIRCMessage getMessageStringForType:msg.command], msg.extra, 1];
            [self sendCommand:ret];
            RBIRCMessage *a = [[RBIRCMessage alloc] initWithRawMessage:ret];
            [[self[a.targets[0]] log] addObject:a];
            break;
        } default:
            break;
    }
}

-(void)dealloc
{
    if ([self connected]) {
        [readStream close];
        [writeStream close];
        [[RBScriptingService sharedInstance] serverDidDisconnect:self];
    }
    readStream = NULL;
    writeStream = NULL;
}

#pragma mark - IRC Commands

-(void)nick:(NSString *)desiredNick
{
    self.nick = desiredNick;
    [self sendCommand:[@"nick " stringByAppendingString:self.nick]];
}

-(void)oper:(NSString *)user password:(NSString *)password
{
    [self sendCommand:[NSString stringWithFormat:@"oper %@ %@", user, password]];
}

-(void)quit
{
    [self quit:@"IRCClient"];
}

-(void)quit:(NSString *)quitMessage
{
    [self sendCommand:[NSString stringWithFormat:@"quit %@", quitMessage]];
}

-(void)join:(NSString *)channelName
{
    [self join:channelName Password:nil];
}

-(void)join:(NSString *)channelName Password:(NSString *)pass
{
    if (channels[channelName] != nil) {
        return;
    }
    RBIRCChannel *c = [[RBIRCChannel alloc] initWithName:channelName];
    c.server = self;
    [channels setObject:c forKey:channelName];
    NSString *msg = [NSString stringWithFormat:@"join %@", channelName];
    if (pass != nil && pass.length > 0) {
        msg = [NSString stringWithFormat:@"%@ %@", msg, pass];
    }
    [self sendCommand:msg];
}

-(void)part:(NSString *)channel
{
    [self part:channel message:@"IRCClient"];
}

-(void)part:(NSString *)channel message:(NSString *)message
{
    if (channels[channel] == nil) {
        @throw [NSError errorWithDomain:@"Invalid Part Command" code:1 userInfo:nil];
    }
    [self sendCommand:[NSString stringWithFormat:@"part %@ :%@", channel, message]];
    [channels removeObjectForKey:channel];
}

-(void)mode:(NSString *)target options:(NSArray *)options
{
    if ([target hasPrefix:@"#"] || [target hasPrefix:@"&"]) {
        if (channels[target] == nil) {
            @throw [NSError errorWithDomain:@"Invalid Mode Command" code:1 userInfo:nil];
        }
    }
    NSString *msg = [NSString stringWithFormat:@"mode %@", target];
    for (NSString *s in options) {
        msg = [NSString stringWithFormat:@"%@ %@", msg, s];
    }
    [self sendCommand:msg];
}

-(void)kick:(NSString *)channel target:(NSString *)target
{
    [self kick:channel target:target reason:self.nick];
}

-(void)kick:(NSString *)channel target:(NSString *)target reason:(NSString *)reason
{
    if (channels[channel] == nil) {
        @throw [NSError errorWithDomain:@"Invalid Kick Command" code:1 userInfo:nil];
    }
    NSString *msg = [NSString stringWithFormat:@"kick %@ %@ :%@", channel, target, reason];
    [self sendCommand:msg];
}

-(void)topic:(NSString *)channel topic:(NSString *)topic
{
    if (channels[channel] == nil) {
        @throw [NSError errorWithDomain:@"Invalid Topic Command" code:1 userInfo:nil];
    }
    [self sendCommand:[NSString stringWithFormat:@"topic %@ :%@", channel, topic]];
}

-(void)privmsg:(NSString *)target contents:(NSString *)message
{
    [self sendCommand:[NSString stringWithFormat:@"privmsg %@ :%@", target, message]];
}

-(void)notice:(NSString *)target contents:(NSString *)message
{
    [self sendCommand:[NSString stringWithFormat:@"notice %@ :%@", target, message]];
}

-(void)sendIRCMessage:(RBIRCMessage *)message
{
    switch (message.command) {
        case IRCMessageTypeJoin:
            for (NSString *to in message.targets) {
                [self join:to];
            }
            break;
        case IRCMessageTypePart:
            for (NSString *to in message.targets) {
                [self part:to message:message.message];
            }
            break;
        case IRCMessageTypePrivmsg:
            for (NSString *to in message.targets) {
                [self privmsg:to contents:message.message];
            }
            break;
        case IRCMessageTypeNotice:
            for (NSString *to in message.targets) {
                [self notice:to contents:message.message];
            }
            break;
        case IRCMessageTypeMode: {
            for (NSString *to in message.targets) {
                [self mode:to options:message.extra];
            }
            break;
        }
        case IRCMessageTypeKick: {
            for (NSString *to in message.targets) {
                [self kick:to target:message.extra[@"target"] reason:message.extra[@"reason"]];
            }
            break;
        }
        case IRCMessageTypeTopic:
            for (NSString *to in message.targets) {
                [self topic:to topic:message.message];
            }
            break;
        case IRCMessageTypeUnknown:
        default:
            break;
    }
}

#pragma mark - NSStreamDelegate

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if ([aStream isKindOfClass:[NSOutputStream class]]) {
                dispatch_async(dispatch_queue_create("", NULL), onConnect);
            }
            break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[513];
            buffer[512] = 0;
            buffer[0] = 0;
            signed long numBytesRead = [(NSInputStream *)aStream read:buffer maxLength:512];
            buffer[numBytesRead] = 0;
            if (numBytesRead > 0) {
                NSString *str = [NSString stringWithUTF8String:(const char *)buffer];
                if ([str hasContent]) {
                    [self.incompleteMessages appendString:str];
                    while ([self.incompleteMessages containsSubstring:@"\r\n"]) {
                        NSRange range = [self.incompleteMessages rangeOfString:@"\r\n"];
                        str = [self.incompleteMessages substringToIndex:range.location + 2];
                        [self.incompleteMessages deleteCharactersInRange:[self.incompleteMessages rangeOfString:str]];
                        [self receivedString:str];
                    }
                } else {
                    printf("%s\n", buffer);
                }
            } else if (numBytesRead < 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerErrorReadingFromStream object:self userInfo:@{@"error": [readStream streamError]}];
            }
            break;
        }
        case NSStreamEventErrorOccurred:
            [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerErrorReadingFromStream object:self userInfo:@{@"error": [aStream streamError]}];
            [[RBScriptingService sharedInstance] serverDidError:self];
            break;
        case NSStreamEventEndEncountered:
            [self.writeStream close];
            [self.readStream close];
            [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerConnectionDidDisconnect object:self userInfo:nil];
            [[RBScriptingService sharedInstance] serverDidDisconnect:self];
            break;
        default:
            break;
    }
}

-(NSArray *)sortedChannelKeys
{
    NSMutableArray *theChannels = [self.channels.allKeys mutableCopy];
    [theChannels removeObject:RBIRCServerLog];
    NSArray *ret = [theChannels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [(NSString *)obj1 compare:(NSString *)obj2];
    }];
    return [@[self.serverName, RBIRCServerLog] arrayByAddingObjectsFromArray:ret];
}

-(void)sendUpdateMessageCommand:(RBIRCMessage *)caller
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerUpdateMessage object:self userInfo:@{@"message": caller}];
}

#pragma mark - Keyed subscripting

-(id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return self.channels[key];
}

-(void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    if (obj == nil) {
        [self.channels removeObjectForKey:key];
    } else {
        self.channels[key] = obj;
    }
}

-(NSString *)description
{
    return self.serverName;
}

@end
