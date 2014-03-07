//
//  RBScriptingService.h
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RBScript;

@class RBIRCServer;
@class RBIRCChannel;
@class RBIRCMessage;

@class RBServerViewController;
@class RBTextFieldServerCell;

@class RBServerEditorViewController;

@class RBChannelViewController;

@interface RBScriptingService : NSObject

@property (nonatomic, readonly) BOOL scriptsLoaded;
@property (nonatomic, strong) NSMutableSet *scriptSet;
@property (nonatomic, strong) NSMutableDictionary *scriptDict; // string: class
@property (nonatomic) BOOL runScriptsConcurrently;

+(RBScriptingService *)sharedInstance;

-(void)loadScripts;
-(void)runEnabledScripts;

-(NSArray *)scripts;

-(void)registerScript:(Class)script;

#pragma mark - IRC Server
-(void)serverDidConnect:(RBIRCServer *)server;
-(void)serverDidDisconnect:(RBIRCServer *)server;
-(void)serverDidError:(RBIRCServer *)server;
-(void)server:(RBIRCServer *)server didReceiveMessage:(RBIRCMessage *)message;

#pragma mark - IRC Channel
-(void)channel:(RBIRCChannel *)channel didLogMessage:(RBIRCMessage *)message;

#pragma mark - Server list view
-(void)serverListWasLoaded:(RBServerViewController *)serverList;

-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell;
-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server;
-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel;
-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation;
-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell;

#pragma mark - Server Editor
-(void)serverEditorWasLoaded:(RBServerEditorViewController *)serverEditor;
-(void)serverEditor:(RBServerEditorViewController *)serverEditor didMakeChangesToServer:(RBIRCServer *)server;
-(void)serverEditorWillBeDismissed:(RBServerEditorViewController *)serverEditor;

#pragma mark - Channel View
-(void)channelViewWasLoaded:(RBChannelViewController *)channelView;
-(void)channelView:(RBChannelViewController *)channelView didDisconnectFromChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server;
-(void)channelView:(RBChannelViewController *)channelView didSelectChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server;
-(void)channelView:(RBChannelViewController *)channelView willDisplayMessage:(RBIRCMessage *)message inView:(UITextView *)view;


@end
