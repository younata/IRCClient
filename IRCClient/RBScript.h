//
//  RBScript.h
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RBIRCServer;
@class RBIRCChannel;
@class RBIRCMessage;

/**
 `RBScript` is the base class for scripts. All scripts should subclass RBScript.
 
 @warning All scripts are called in the order the system creates them, and are generally handed the raw objects (as opposed to copies). Only modify the object if you know what you're doing.
 */
@interface RBScript : NSObject

/**
 Gets called right after a message has been interpretted.
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -messageLogged:server:
 */
-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server;

/**
 Gets called right after the server has logged an IRCMessage to its respective channels.
 
 Note that this is called after the raw message is logged to the channel, but before it is sent off to the server delegates.
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -messageReceived:server:
 */
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server;

@end
