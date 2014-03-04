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
@class RBServerEditorViewController;
@class RBChannelViewController;

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

/**
 Gets called for configuration.
 
 @return a dictionary, expected to be of form {settingName (string): settingType (string)}.
 This defaults to nil.
 */
+(NSDictionary *)configurationItems;

///@name IRC Server

/**
 Do additional things after a server has connected
 
 @param server - the server which just connected
 */
-(void)serverDidConnect:(RBIRCServer *)server;

/**
 Do additional thinsg after a server has disconnected
 
 @param server - the server which sent this message
 */
-(void)serverDidDisconnect:(RBIRCServer *)server;

/**
 Do additional thinsg after a server has received an error with its connection.
 
 @param server - the server which sent this message
 */
-(void)serverDidError:(RBIRCServer *)server;

/**
 Gets called right after a message has been interpretted.
 
 @param server - server which recieved the message
 @param message - the parsed message
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -channel:didLogMessage:
 */
-(void)server:(RBIRCServer *)server didReceiveMessage:(RBIRCMessage *)message;

/// @name IRC Channel

/**
 Gets called right after the server has logged an IRCMessage to its respective channels.
 
 Note that this is called after the raw message is logged to the channel, but before it is sent off to the server delegates.
 
 @param channel - the channel which logged this message
 @param message - the parsed message
 
 @warning The RFC forbids auto-responding to NOTICEs. Not that this stops you, but it is considered bad practice.
 @warning The RFC also recommends that, if a PRIVMSG is auto-responded, a NOTICE is sent out.
 
 @see -server:didReceiveMessage:
 */
-(void)channel:(RBIRCChannel *)channel didLogMessage:(RBIRCMessage *)message;

///@name Server List View

/**
 Do additional things to the server list after it loads.
 
 @param serverList - the ServerViewController which originally sent this message
 */
-(void)serverListWasLoaded:(RBServerViewController *)serverList;

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

/// @name Server Editor

/**
 Do additional things to a server editor after it has loaded
 
 @param serverEditor - the ServerEditorViewController which originally sent this message
 */
-(void)serverEditorWasLoaded:(RBServerEditorViewController *)serverEditor;

/**
 Do additional things to a server right before it is saved to NSUserDefaults
 
 @param serverEditor - the ServerEditorViewController which originally sent this message
 @param server - the IRCServer which is being edited
 */
-(void)serverEditor:(RBServerEditorViewController *)serverEditor didMakeChangesToServer:(RBIRCServer *)server;

/**
 Do additional things to a server editor right before it gets dismissed.
 
 @param serverEditor - the ServerEditorViewController which originally sent this message
 */
-(void)serverEditorWillBeDismissed:(RBServerEditorViewController *)serverEditor;

/// @name Channel View

/**
 Do additional things to a channel view after it has loaded
 
 @param channelView - the ChannelViewController which sent this message
 */
-(void)channelViewWasLoaded:(RBChannelViewController *)channelView;

/**
 Do additional things after the channel view has called -disconnect
 
 @param channelView - the ChannelViewController which sent this message
 @param channel - the channel who's log it was displaying
 @param server - the server the channel belonged to
 */
-(void)channelView:(RBChannelViewController *)channelView didDisconnectFromChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server;

/**
 Do additional things after a channel view has started to display the log of a channel
 
 @param channelView - the ChannelViewController which sent this message
 @param channel - the channel who's log it is now displaying
 @param server - the server the channel belonged to
 */
-(void)channelView:(RBChannelViewController *)channelView didSelectChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server;


@end
