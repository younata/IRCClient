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

@interface RBIRCServer ()

@property (nonatomic, readwrite) BOOL connected;
@property (nonatomic, strong) NSMutableArray *commandQueue;

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
        _connected = NO;
        
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
        _delegates = [[NSMutableArray alloc] init];
        
        self.commandQueue = [[NSMutableArray alloc] init];
        
        if (self.connectOnStartup) {
            [self connect];
            for (NSString *key in self.channels.allKeys) {
                if ([key isEqualToString:RBIRCServerLog]) {
                    continue;
                }
                RBIRCChannel *channel = self.channels[key];
                if (channel.connectOnStartup) {
                    NSString *s = [NSString stringWithFormat:@"join %@", key];
                    if ([channel.password hasContent]) {
                        s = [NSString stringWithFormat:@"%@ %@", s, channel.password];
                    }
                    s = [NSString stringWithFormat:@"%@\r\n", s];
                    [self.commandQueue addObject:s];
                }
            }
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
    [coder encodeObject:self.channels forKey:@"channels"];
}

-(void)commonInit
{
    _delegates = [[NSMutableArray alloc] init];
    channels = [[NSMutableDictionary alloc] init];
    RBIRCChannel *serverLog = [[RBIRCChannel alloc] initWithName:RBIRCServerLog];
    serverLog.connectOnStartup = YES;
    [channels setObject:serverLog forKey:RBIRCServerLog];
    
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
    command = [command stringByAppendingString:@"\r\n"];
    signed long numBytesWritten = [writeStream write:(const unsigned char *)[command UTF8String] maxLength:[command length]];
    if (numBytesWritten < 0) {
        NSError *error = [writeStream streamError];
        NSLog(@"Error Writing to stream: %@", error);
    } else if (numBytesWritten == 0) {
        if ([writeStream streamStatus] == kCFStreamStatusAtEnd) {
            for (id<RBIRCServerDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(IRCServerConnectionDidDisconnect:)])
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
    
    [self.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if (self.useSSL) {
        [self.readStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        [self.writeStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
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
        theSelf.connected = YES;
        for (id<RBIRCServerDelegate> del in theSelf.delegates) {
            if ([del respondsToSelector:@selector(IRCServerDidConnect:)])
                [del IRCServerDidConnect:theSelf];
        }
        if (theSelf.debugLock)
            [theSelf.debugLock unlock];
    };
}

-(void)receivedString:(NSString *)str
{
    printf("%s\n", [str UTF8String]); // Debug! Without the annoying timestamp NSLog adds.
    if ([str hasPrefix:@"PING"]) { // quickly handle pings.
        [self sendCommand:[str stringByReplacingOccurrencesOfString:@"PING" withString:@"PONG"]];
    } else {
        RBIRCMessage *msg;
        @try {
            msg = [[RBIRCMessage alloc] initWithRawMessage:str];
        }
        @catch (NSException *exception) {
            NSLog(@"error parsing message '%@'\nException: %@", str, exception); // I'm bad and I should feel bad.
            msg = nil;
        }
        if (!msg)
            return;
        RBIRCChannel *ch;
        if (![[msg to] hasContent] || [[msg to] isEqualToString:@"*"]) {
            ch = [channels objectForKey:RBIRCServerLog];
            msg.message = msg.rawMessage;
            msg.to = RBIRCServerLog;
        } else {
            if (channels[[msg to]] != nil) {
                ch = channels[[msg to]];
            } else {
                ch = [[RBIRCChannel alloc] initWithName:[msg to]];
                [channels setObject:ch forKey:[msg to]];
                ch.server = self;
            }
        }
        [ch logMessage:msg];
        
        for (id<RBIRCServerDelegate>del in self.delegates) {
            if ([del respondsToSelector:@selector(IRCServer:handleMessage:)])
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
            if ([del respondsToSelector:@selector(IRCServer:invalidCommand:)])
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
                if ([del respondsToSelector:@selector(IRCServer:invalidCommand:)])
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
            if ([del respondsToSelector:@selector(IRCServer:invalidCommand:)])
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
            if ([del respondsToSelector:@selector(IRCServer:invalidCommand:)])
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
        case NSStreamEventOpenCompleted: {
            if ([aStream isKindOfClass:[NSOutputStream class]]) {
                dispatch_async(dispatch_queue_create("", NULL), onConnect);
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[513];
            buffer[512] = 0;
            buffer[0] = 0;
            signed long numBytesRead = [(NSInputStream *)aStream read:buffer maxLength:512];
                if (numBytesRead > 0) {
                    NSString *str = [NSString stringWithUTF8String:(const char *)buffer];
                    if (str != nil) {
                        [self receivedString:str];
                    }
                } else if (numBytesRead < 0) {
                    for (id<RBIRCServerDelegate>del in self.delegates) {
                        if ([del respondsToSelector:@selector(IRCServer:errorReadingFromStream:)])
                            [del IRCServer:self errorReadingFromStream:[readStream streamError]];
                    }
                }
            break;
        }
        default:
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
