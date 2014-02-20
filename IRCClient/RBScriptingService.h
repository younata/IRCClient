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
{
    NSMutableArray *scripts;
}

@property (nonatomic, readonly, strong) NSArray *scripts;

+(RBScriptingService *)sharedInstance;

-(void)registerScript:(RBScript *)script;

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server;
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server;


@end
