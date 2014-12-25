//
//  RBDataManager.h
//  IRCClient
//
//  Created by Rachel Brindle on 6/16/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Nick.h"
#import "Server.h"
#import "Channel.h"

@class RBIRCServer;

@interface RBDataManager : NSObject

+ (RBDataManager *)sharedInstance;

- (UIColor *)colorForNick:(NSString *)nick onServer:(NSString *)serverName; // creates or returns existing...
- (Server *)serverForServerName:(NSString *)serverName; // creates or returns existing...
- (Server *)serverWithProperty:(id)property propertyName:(NSString *)propertyName;
- (Server *)serverMatchingIRCServer:(RBIRCServer *)server;
- (Channel *)channelMatchingIRCChannel:(RBIRCChannel *)ircChannel;
- (Nick *)nick:(NSString *)name onServer:(Server *)server; // creates or returns existing...

- (NSArray *)servers;

@end
