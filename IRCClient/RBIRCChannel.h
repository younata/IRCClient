//
//  RBIRCChannel.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RBIRCMessage;
@class RBIRCServer;

@class Channel;

@interface RBIRCChannel : NSObject <NSCoding>

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSMutableArray *log;
@property (nonatomic, readonly, strong) NSMutableArray *names;
@property (nonatomic, weak) RBIRCServer *server;
@property (nonatomic, copy) NSString *topic;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL askedForNames;

@property (nonatomic, readonly, strong) NSArray *unreadMessages;

+(BOOL)isNickAUser:(NSString *)nick;

-(instancetype)initFromChannel:(Channel *)channel;
-(instancetype)initWithName:(NSString *)name;
-(void)logMessage:(RBIRCMessage *)message;
-(BOOL)isChannel; // or PM...
-(NSArray *)read;

@end
