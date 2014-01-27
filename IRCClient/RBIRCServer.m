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

@interface RBIRCServer ()
{
    NSString *standardPrefix;
}

@end

@implementation RBIRCServer

@synthesize channels;
@synthesize nick;

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
    }
    return self;
}

-(void)sendCommand:(NSString *)command
{
    command = [command stringByAppendingString:@"\r\n"];
    signed long numBytesWritten = CFWriteStreamWrite(writeStream, (const unsigned char *)[command UTF8String], [command length]);
    if (numBytesWritten < 0) {
        CFErrorRef error = CFWriteStreamCopyError(writeStream);
        NSLog(@"Error Writing to stream: %@", (__bridge_transfer NSError *)error);
    } else if (numBytesWritten == 0) {
        if (CFWriteStreamGetStatus(writeStream) == kCFStreamStatusAtEnd) {
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
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)self.hostname, [self.port intValue], &readStream, &writeStream);
    CFWriteStreamOpen(writeStream);
    CFReadStreamOpen(readStream);
    [(__bridge_transfer NSInputStream *)readStream setDelegate:self];
    channels = [[NSMutableDictionary alloc] init];
    if (pass != nil || [pass length] > 0) {
        [self sendCommand:[@"pass " stringByAppendingString:pass]];
    }
    [self nick:nick];
    [self sendCommand:[NSString stringWithFormat:@"user %@ foo bar %@", self.nick, realname]];
    _connected = YES;
}

-(void)receivedString:(NSString *)str
{
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
        if (CFReadStreamGetStatus(readStream) == kCFStreamStatusOpen) {
            CFReadStreamClose(readStream);
            CFWriteStreamClose(writeStream);
        }
        CFRelease(readStream);
        CFRelease(writeStream);
    }
    readStream = NULL;
    writeStream = NULL;
}

#pragma mark - IRC Commands

-(void)nick:(NSString *)desiredNick
{
    nick = desiredNick;
    [self sendCommand:[@"nick " stringByAppendingString:nick]];
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
    [c join:channelName];
    [channels setObject:c forKey:channelName];
}

-(void)part:(NSString *)channel
{
    [self part:channel message:@"IRCClient"];
}

-(void)part:(NSString *)channel message:(NSString *)message
{
    if (channels[channel] == nil) {
        return;
    }
    [channels[channel] part:message];
    [self sendCommand:[NSString stringWithFormat:@"part %@ %@", channel, message]];
    [channels removeObjectForKey:channel];
}

-(void)channelMode:(NSString *)channel options:(NSString *)options
{
    [channels[channel] mode:options];
}

-(void)topic:(NSString *)channel topic:(NSString *)topic
{
    [self sendCommand:[NSString stringWithFormat:@"topic %@ %@", channel, topic]];
}

#pragma mark - NSStreamDelegate

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[513];
            buffer[512] = 0;
            signed long numBytesRead = CFReadStreamRead(readStream, buffer, 512);
            do {
                if (numBytesRead > 0) {
                    NSString *str = [NSString stringWithUTF8String:(const char *)buffer];
                    [self receivedString:str];
                    
                } else if (numBytesRead < 0) {
                    for (id<RBIRCServerDelegate>del in self.delegates) {
                        [del IRCServer:self errorReadingFromStream:(__bridge_transfer NSError *)CFReadStreamCopyError(readStream)];
                    }
                    //CFErrorRef error = CFReadStreamCopyError(readStream);
                    //NSLog(@"Error reading from stream: %@", (__bridge_transfer NSError *)error);
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

@end
