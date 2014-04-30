//
//  RBIRCServer.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CFNetwork/CFNetwork.h>

@class RBIRCMessage;

#define RBIRCServerLog @"ServerLog"

#define RBIRCServerDidConnect @"RBIRCServerDidConnect"
#define RBIRCServerConnectionDidDisconnect @"RBIRCServerConnectionDidDisconnect"
#define RBIRCServerErrorReadingFromStream @"RBIRCServerErrorReadingFromStream"
#define RBIRCServerHandleMessage @"RBIRCServerHandleMessage"
#define RBIRCServerInvalidCommand @"RBIRCServerInvalidCommand"
#define RBIRCServerUpdateMessage @"RBIRCServerUpdateMessage"


@interface RBIRCServer : NSObject <NSStreamDelegate, NSCoding>
{
    NSInputStream *readStream;
    NSOutputStream *writeStream;
    
    void (^onConnect)(void);
}

@property (nonatomic, strong) NSInputStream *readStream;
@property (nonatomic, strong) NSOutputStream *writeStream;

@property (nonatomic, readonly, strong) NSMutableDictionary *channels;
@property (nonatomic, copy) NSString *serverName;

@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSLock *debugLock;
@property (nonatomic) BOOL useSSL;
@property (nonatomic, readonly) BOOL connected;

@property (nonatomic) BOOL connectOnStartup;

-(instancetype)initWithHostname:(NSString *)hostname ssl:(BOOL)useSSL port:(NSString *)port nick:(NSString *)nick realname:(NSString *)realname password:(NSString *)password;
-(void)sendCommand:(NSString *)command;

-(void)reconnect;

-(void)connect;
-(void)connect:(NSString *)realname;
-(void)connect:(NSString *)realname withPassword:(NSString *)pass;

-(void)receivedString:(NSString *)str;

// irc commands.
-(void)nick:(NSString *)desiredNick;

-(void)oper:(NSString *)user password:(NSString *)password;

-(void)quit;
-(void)quit:(NSString *)quitMessage;

-(void)join:(NSString *)channelName;
-(void)join:(NSString *)channelName Password:(NSString *)pass;

-(void)part:(NSString *)channel;
-(void)part:(NSString *)channel message:(NSString *)message;

-(void)mode:(NSString *)target options:(NSArray *)options;

-(void)kick:(NSString *)channel target:(NSString *)target;
-(void)kick:(NSString *)channel target:(NSString *)target reason:(NSString *)reason;

-(void)topic:(NSString *)channel topic:(NSString *)topic;

-(void)privmsg:(NSString *)target contents:(NSString *)message;
-(void)notice:(NSString *)target contents:(NSString *)message;

-(void)sendIRCMessage:(RBIRCMessage *)message;

-(NSArray *)sortedChannelKeys;

-(void)sendUpdateMessageCommand:(RBIRCMessage *)caller;

// yay making things easier...
-(id)objectForKeyedSubscript:(id <NSCopying>)key;
-(void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

// OH god, does cedar spying really need this?
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;

@end
