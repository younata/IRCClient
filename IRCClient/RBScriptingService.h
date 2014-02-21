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

@interface RBScriptingService : NSObject

@property (nonatomic, readonly) BOOL scriptsLoaded;
@property (nonatomic, strong) NSMutableSet *scriptSet;
@property (nonatomic, strong) NSMutableDictionary *scriptDict; // string: class

+(RBScriptingService *)sharedInstance;

-(void)loadScripts;
-(void)runEnabledScripts;

-(NSArray *)scripts;

-(void)registerScript:(Class)script;

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server;
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server;


@end
