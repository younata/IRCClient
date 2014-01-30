//
//  RBServerHandler.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RBIRCServer;
@class RBIRCMessage;
@protocol RBIRCServerDelegate <NSObject>

@optional
-(void)IRCServerDidConnect:(RBIRCServer *)server;
-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server;
-(void)IRCServer:(RBIRCServer *)server errorReadingFromStream:(NSError *)error;

-(void)IRCServer:(RBIRCServer *)server handleMessage:(RBIRCMessage *)message;

-(void)IRCServer:(RBIRCServer *)server invalidCommand:(NSError *)error;

@end
