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
@class RBServerViewController;
@class RBTextFieldServerCell;

/**
 `RBScript` is the base class for scripts. All scripts should subclass RBScript.
 
 @warning All scripts are called in the order the system creates them, and are generally handed the raw objects (as opposed to copies). Only modify the object if you know what you're doing.
 @warning There is no namespace collision detection amongst scripts. Try to be unique in your class name and class description...
 */
@interface RBScript : NSObject

/**
 Gets called by the scripting service for the name of the script.
 
 By default this just returns NSStringFromClass(self), implement your own version for a more detailed description.
 Note that the value of this is what's shown in the configure view for settings which scripts are turned on.
 */
+(NSString *)description;

+(NSDictionary *)configurationItems;

/**
 Gets called right after a message has been interpretted.
 
 @param message - the parsed message
 @param server - server which recieved the message
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -messageLogged:server:
 */
-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server;

/**
 Gets called right after the server has logged an IRCMessage to its respective channels.
 
 Note that this is called after the raw message is logged to the channel, but before it is sent off to the server delegates.
 
 @param message - the parsed message
 @param server - server which recieved the message
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -messageReceived:server:
 */
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server;

///@name Server List View

/**
 Do additional things to a cell which will hold a message/prompt for the user to set up a connection to a new server.
 
 @param serverList - the ServerViewController which originally sent this message
 @param cell - the created cell
 */
-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell;

/**
 Do additional things to a cell which will hold a message/prompt for the user to modify the connection for an existing server
 
 @param serverList - the ServerViewController which originally sent this message
 @param cell - the created cell
 @param server - the server which backs the cell
 */
-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server;

/**
 Do additional things to a cell which represents a channel (has prefix '#' or '&').
 
 @param serverList - the ServerViewController which originally sent this message
 @param cell - the created cell
 @param channel - the backing channel
 */
-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel;

/**
 Do additional things to a cell which represents a conversation.
 
 @param serverList - the ServerViewController which originally sent this message
 @param cell - the created cell
 @param conversation - the backing conversation
 */
-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation;

/**
 Do additional things to a cell which will hold a message/prompt for the user to connect to a new channel/send a pm to another user.
 
 @param serverList - the ServerViewController which originally sent this message
 @param cell - the created cell
 */
-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell;


@end
