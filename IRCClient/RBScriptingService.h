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

@interface RBScriptingService : NSObject

@property (nonatomic, readonly) BOOL scriptsLoaded;
@property (nonatomic, strong) NSMutableSet *scriptSet;
@property (nonatomic, strong) NSMutableDictionary *scriptDict; // string: class

+(RBScriptingService *)sharedInstance;

-(void)loadScripts;
-(void)runEnabledScripts;

-(NSArray *)scripts;

-(void)registerScript:(Class)script;

#pragma mark - messages
-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server;
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server;

#pragma mark - Server list view
// creating...
-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell;
-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server;
-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel;
-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation;
-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell;

@end
