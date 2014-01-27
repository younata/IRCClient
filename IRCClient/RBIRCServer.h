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

#import "RBIRCServerDelegate.h"

@interface RBIRCServer : NSObject <NSStreamDelegate>
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSMutableArray *commandQueue;
}

@property (nonatomic, readonly, strong) NSMutableArray *delegates;
@property (nonatomic, readonly, strong) NSMutableDictionary *channels;
@property (nonatomic, copy) NSString *serverName;

@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *password;
@property (nonatomic) BOOL useSSL;
@property (nonatomic, readonly) BOOL connected;

-(instancetype)initWithHostname:(NSString *)hostname ssl:(BOOL)useSSL port:(NSString *)port nick:(NSString *)nick realname:(NSString *)realname password:(NSString *)password;
-(void)sendCommand:(NSString *)command;

-(void)addDelegate:(id<RBIRCServerDelegate>)object;
-(void)rmDelegate:(id<RBIRCServerDelegate>)object;

-(void)connect;
-(void)connect:(NSString *)realname;
-(void)connect:(NSString *)realname withPassword:(NSString *)pass;

-(void)join:(NSString *)channelName;

-(id)objectForKeyedSubscript:(id <NSCopying>)key;
-(void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

@end
