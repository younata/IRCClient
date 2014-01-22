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

@class RBIRCServer;
@protocol RBIRCServerDelegate <NSObject>

-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server;
-(void)IRCServer:(RBIRCServer *)server errorReadingFromStream:(NSError *)error;

@end

@interface RBIRCServer : NSObject <NSStreamDelegate>
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSMutableArray *commandQueue;
    
    NSString *nick;
    NSMutableArray *channels;
}

@property (nonatomic, weak) id<RBIRCServerDelegate> delegate;

-(instancetype)initWithHostname:(NSString *)hostname ssl:(BOOL)useSSL port:(NSString *)port nick:(NSString *)nick realname:(NSString *)realname password:(NSString *)password;
-(void)sendCommand:(NSString *)command;
-(void)connect:(NSString *)realname;
-(void)connect:(NSString *)realname withPassword:(NSString *)pass;
-(void)join:(NSString *)channelName;

@end
