//
//  RBIRCServer.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Blindside/Blindside.h>

#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "RBIRCChannel.h"
#import "NSStream+remoteHost.h"
#import "NSString+isNilOrEmpty.h"
#import "NSString+contains.h"

#import "Server.h"
#import "Channel.h"
#import "RBDataManager.h"

@interface RBIRCServer ()

@property (nonatomic, strong) NSMutableArray *commandQueue;
@property (nonatomic, strong) NSMutableString *incompleteMessages;
@property (nonatomic) NSInteger reconnectDelay;
@property (nonatomic, strong) id<BSInjector> injector;

@end

@implementation RBIRCServer

-(void)configureWithHostname:(NSString *)hostname
                         ssl:(BOOL)useSSL
                        port:(NSString *)port
                        nick:(NSString *)nick
                    realname:(NSString *)realname
                    password:(NSString *)password
{
    self.nick = nick;
    self.hostname = hostname;
    self.port = port;
    self.useSSL = useSSL;
    self.realname = realname;
    self.password = password;

    _channels = [[NSMutableDictionary alloc] init];

    RBIRCChannel *serverLog = [[RBIRCChannel alloc] initWithName:RBIRCServerLog];
    [self.channels setObject:serverLog forKey:RBIRCServerLog];

    self.incompleteMessages = [[NSMutableString alloc] init];

    self.reconnectDelay = 1;
}

-(void)configureWithServer:(Server *)server
{
    self.nick = server.nick;
    self.serverName = server.name;
    self.hostname = server.host;
    self.password = server.password;
    self.port = server.port;
    self.realname = server.realname;
    self.useSSL = server.ssl.boolValue;
    NSMutableDictionary *theChannels = [[NSMutableDictionary alloc] init];
    for (Channel *channel in server.channels) {
        theChannels[channel.name] = [[RBIRCChannel alloc] initFromChannel:channel];
    }
    _channels = theChannels;
}

-(void)reconnect
{
    [self connect];
    for (NSString *key in self.channels.allKeys) {
        if ([key isEqualToString:RBIRCServerLog]) {
            continue;
        }
        RBIRCChannel *channel = self.channels[key];
        if (channel.isChannel) {
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

-(void)sendCommand:(NSString *)cmd
{
    if (!self.connected) {
        return;
    }
    dispatch_async([RBIRCServer queue], ^{
        NSString *command = cmd;
        if (command.length > 512) {
            if ([command.lowercaseString hasPrefix:@"privmsg"] || [command.lowercaseString hasPrefix:@"notice"]) {
                NSString *cmd1 = [command substringToIndex:510];
                NSString *cmd2 = [command substringFromIndex:510];
                NSString *prefix = [command substringToIndex:[command rangeOfString:@":"].location + 1];
                [self sendCommand:cmd1];
                [self sendCommand:[prefix stringByAppendingString:cmd2]];
            }
            return;
        }
        if (![command hasSuffix:[NSString stringWithFormat:@"\r\n"]]) {
            command = [command stringByAppendingString:@"\r\n"];
        }
        
        signed long numBytesWritten = [self.writeStream write:(const unsigned char *)[command UTF8String] maxLength:[command length]];
        if (numBytesWritten < 0) {
            NSError *error = [self.writeStream streamError];
            NSLog(@"Error Writing to stream: %@", error);
            [self.writeStream close];
            [self.readStream close];
        } else if (numBytesWritten == 0) {
            if ([self.writeStream streamStatus] == kCFStreamStatusAtEnd) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerConnectionDidDisconnect object:self userInfo:nil];
            }
        } else if (numBytesWritten != [command length]) {
            NSString *cmd = [command substringWithRange:NSMakeRange(numBytesWritten, [command length] - (2 + numBytesWritten))];
            [self sendCommand:cmd];
        }
    });
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
        [self.readStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        [self.writeStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        CFReadStreamSetProperty((__bridge_retained CFReadStreamRef)self.readStream, kCFStreamPropertySSLSettings, nil);
        CFWriteStreamSetProperty((__bridge_retained CFWriteStreamRef)self.writeStream, kCFStreamPropertySSLSettings, nil);

    }
    
    [self.readStream setDelegate:self];
    [self.writeStream setDelegate:self];
    
    [self.writeStream open];
    [self.readStream open];
    
    RBIRCServer *theSelf = (RBIRCServer *)self;
    onConnect = ^{
        theSelf.reconnectDelay = 1;
        if ([pass hasContent]) {
            [theSelf sendCommand:[@"pass " stringByAppendingString:pass]];
        }
        [theSelf nick:theSelf.nick];
        [theSelf sendCommand:[NSString stringWithFormat:@"user %@ foo bar %@", theSelf.nick, realname]];
        [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerDidConnect object:theSelf userInfo:nil];
        if (theSelf.debugLock)
            [theSelf.debugLock unlock];
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
            ch = [self.channels objectForKey:RBIRCServerLog];
            msg.message = msg.rawMessage;
            to = RBIRCServerLog;
            msg.targets[i] = to;
        } else {
            if (self.channels[to] != nil) {
                ch = self.channels[to];
            } else {
                ch = [[RBIRCChannel alloc] initWithName:to];
                [self.channels setObject:ch forKey:to];
                ch.server = self;
            }
        }
        [ch logMessage:msg];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerHandleMessage object:self userInfo:@{@"message": msg}];
    });
    
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
            RBIRCChannel *channel = self[a.targets[0]];
            [channel logMessage:a];
            break;
        } default:
            break;
    }
}

-(void)dealloc
{
    if ([self connected]) {
        [self.readStream close];
        [self.writeStream close];
    }
    self.readStream = NULL;
    self.writeStream = NULL;
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
    if (self.channels[channelName] != nil) {
        return;
    }
    RBIRCChannel *c = [[RBIRCChannel alloc] initWithName:channelName];
    c.server = self;
    [self.channels setObject:c forKey:channelName];
    
    NSArray *comps = [channelName componentsSeparatedByString:@","];
    if (comps.count > 1) {
        channelName = @"";
        for (NSString *n in comps) {
            NSString *name = n;
            if (![n hasPrefix:@"#"]) {
                name = [@"#" stringByAppendingString:n];
            }
            channelName = [channelName stringByAppendingFormat:@"%@ ", name];
        }
    }
    
    channelName = [channelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
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
    if (self.channels[channel] == nil) {
        @throw [NSError errorWithDomain:@"Invalid Part Command" code:1 userInfo:nil];
    }
    [self sendCommand:[NSString stringWithFormat:@"part %@ :%@", channel, message]];
    RBIRCChannel *ircChannel = self.channels[channel];
    [self.channels removeObjectForKey:channel];
    Channel *theChannel = [[RBDataManager sharedInstance] channelMatchingIRCChannel:ircChannel onServer:[[RBDataManager sharedInstance] serverMatchingIRCServer:self]];
    [theChannel.server removeChannelsObject:theChannel];
    [theChannel.managedObjectContext deleteObject:theChannel];
}

-(void)mode:(NSString *)target options:(NSArray *)options
{
    if ([target hasPrefix:@"#"] || [target hasPrefix:@"&"]) {
        if (self.channels[target] == nil) {
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
    if (self.channels[channel] == nil) {
        @throw [NSError errorWithDomain:@"Invalid Kick Command" code:1 userInfo:nil];
    }
    NSString *msg = [NSString stringWithFormat:@"kick %@ %@ :%@", channel, target, reason];
    [self sendCommand:msg];
}

-(void)topic:(NSString *)channel topic:(NSString *)topic
{
    if (self.channels[channel] == nil) {
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

+(dispatch_queue_t)queue
{
    static dispatch_queue_t ret = 0;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        ret = dispatch_queue_create("RBIRCServer", NULL);
    });
    return ret;
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    dispatch_async([RBIRCServer queue], ^{
        [self handleStream:aStream withEvent:eventCode];
    });
}

- (void)handleStream:(NSStream *)aStream withEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if ([aStream isKindOfClass:[NSOutputStream class]]) {
                onConnect();
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
                }
            }
            break;
        }
        case NSStreamEventErrorOccurred: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerErrorReadingFromStream object:self userInfo:@{@"error": [aStream streamError]}];
            });
            self.reconnectDelay *= 2; // fairly common retry decay rate...
            [self performSelector:@selector(connect) withObject:nil afterDelay:self.reconnectDelay];
            break;
        }
        case NSStreamEventEndEncountered: {
            [self.writeStream close];
            [self.readStream close];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RBIRCServerConnectionDidDisconnect object:self userInfo:nil];
            });
            break;
        }
        default:
            break;
    }
}

-(NSArray *)sortedChannelKeys
{
    if (self.serverName == nil) {
        return nil;
    }
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
