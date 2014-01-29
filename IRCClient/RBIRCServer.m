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

@implementation RBIRCServer

@synthesize readStream;
@synthesize writeStream;

@synthesize channels;
@synthesize nick;

-(instancetype)init
{
    if ((self = [super init])) {
        _delegates = [[NSMutableArray alloc] init];
        channels = [[NSMutableDictionary alloc] init];
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
        _connected = NO;
        
        _delegates = [[NSMutableArray alloc] init];
        channels = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/*
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
                                if (self.connected == s.connected)
                                    return YES;
    return NO;
}
 */

-(void)sendCommand:(NSString *)command
{
    command = [command stringByAppendingString:@"\r\n"];
    signed long numBytesWritten = [writeStream write:(const unsigned char *)[command UTF8String] maxLength:[command length]];
    if (numBytesWritten < 0) {
        NSError *error = [writeStream streamError];
        NSLog(@"Error Writing to stream: %@", error);
    } else if (numBytesWritten == 0) {
        if ([writeStream streamStatus] == kCFStreamStatusAtEnd) {
            for (id<RBIRCServerDelegate> del in self.delegates) {
                [del IRCServerConnectionDidDisconnect:self];
            }
        }
    } else if (numBytesWritten != [command length]) {
        NSString *cmd = [command substringWithRange:NSMakeRange(numBytesWritten, [command length] - (2 + numBytesWritten))];
        [self sendCommand:cmd];
    }
}

-(void)addDelegate:(id<RBIRCServerDelegate>)object
{
    [self.delegates addObject:object];
}

-(void)rmDelegate:(id<RBIRCServerDelegate>)object
{
    [self.delegates removeObject:object];
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
    NSInputStream *is;
    NSOutputStream *os;
    [NSStream getStreamsToHost:self.hostname port:self.port inputStream:&is outputStream:&os];
    
    self.readStream = is;
    self.writeStream = os;
    
    [self.writeStream open];
    [self.readStream open];
    
    NSAssert(self.writeStream.streamStatus == NSStreamStatusOpen || self.writeStream.streamStatus == NSStreamStatusOpening, @"write status should be open");
    NSAssert(self.readStream.streamStatus == NSStreamStatusOpen || self.writeStream.streamStatus == NSStreamStatusOpening, @"read status should be open");
    
    [self.readStream setDelegate:self];
    channels = [[NSMutableDictionary alloc] init];
    if (pass != nil || [pass length] > 0) {
        [self sendCommand:[@"pass " stringByAppendingString:pass]];
    }
    [self nick:self.nick];
    [self sendCommand:[NSString stringWithFormat:@"user %@ foo bar %@", self.nick, realname]];
    _connected = YES;
}

-(void)receivedString:(NSString *)str
{
    NSLog(@"%@", str); // Debug!
    if ([str hasPrefix:@"PING"]) { // quickly handle pings.
        [self sendCommand:[str stringByReplacingOccurrencesOfString:@"PING" withString:@"PONG"]];
    } else {
        RBIRCMessage *msg = [[RBIRCMessage alloc] initWithRawMessage:str];
        RBIRCChannel *ch = [[RBIRCChannel alloc] initWithName:[msg to]];
        if (channels[[msg to]] != nil) {
            RBIRCChannel *channel = channels[[msg to]];
            [channel logMessage:msg];
        } else {
            [channels setObject:ch forKey:[msg to]];
            ch.server = self;
            [ch logMessage:msg];
        }
        for (id<RBIRCServerDelegate>del in self.delegates) {
            [del IRCServer:self handleMessage:msg];
        }
    }
}

-(void)dealloc
{
    if (readStream != NULL) {
        if ([readStream streamStatus] == kCFStreamStatusOpen) {
            [readStream close];
            [writeStream close];
        }
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
        for (id<RBIRCServerDelegate>del in self.delegates) {
            [del IRCServer:self invalidCommand:[NSError errorWithDomain:@"Invalid Part Command" code:1 userInfo:nil]];
        }
        return;
    }
    [self sendCommand:[NSString stringWithFormat:@"part %@ :%@", channel, message]];
    [channels removeObjectForKey:channel];
}

-(void)mode:(NSString *)target options:(NSArray *)options
{
    if ([target hasPrefix:@"#"] || [target hasPrefix:@"&"]) {
        if (channels[target] == nil) {
            for (id<RBIRCServerDelegate>del in self.delegates) {
                [del IRCServer:self invalidCommand:[NSError errorWithDomain:@"Invalid Mode Command" code:1 userInfo:nil]];
            }
            return;
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
        for (id<RBIRCServerDelegate>del in self.delegates) {
            [del IRCServer:self invalidCommand:[NSError errorWithDomain:@"Invalid Kick Command" code:1 userInfo:nil]];
        }
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"kick %@ %@ :%@", channel, target, reason];
    [self sendCommand:msg];
}

-(void)topic:(NSString *)channel topic:(NSString *)topic
{
    if (channels[channel] == nil) {
        for (id<RBIRCServerDelegate>del in self.delegates) {
            [del IRCServer:self invalidCommand:[NSError errorWithDomain:@"Invalid Topic Command" code:1 userInfo:nil]];
        }
        return;
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
            [self join:message.to];
            break;
        case IRCMessageTypePart:
            [self part:message.to message:message.message];
            break;
        case IRCMessageTypePrivmsg:
            [self privmsg:message.to contents:message.message];
            break;
        case IRCMessageTypeNotice:
            [self notice:message.to contents:message.message];
            break;
        case IRCMessageTypeMode: {
            [self mode:message.to options:message.extra];
            break;
        }
        case IRCMessageTypeKick: {
            [self kick:message.to target:message.extra[@"target"] reason:message.extra[@"reason"]];
            break;
        }
        case IRCMessageTypeTopic:
            [self topic:message.to topic:message.message];
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
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[513];
            buffer[512] = 0;
            buffer[0] = 0;
            signed long numBytesRead = [(NSInputStream *)aStream read:buffer maxLength:512];
            do {
                if (numBytesRead > 0) {
                    NSString *str = [NSString stringWithUTF8String:(const char *)buffer];
                    [self receivedString:str];
                } else if (numBytesRead < 0) {
                    for (id<RBIRCServerDelegate>del in self.delegates) {
                        [del IRCServer:self errorReadingFromStream:[readStream streamError]];
                    }
                }
            } while (numBytesRead > 0);
            break;
        } default:
            break;
    }
}

#pragma mark - Keyed subscripting

-(id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return self.channels[key];
}

-(void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    self.channels[key] = obj;
}

-(NSString *)description
{
    return self.serverName;
}

@end
