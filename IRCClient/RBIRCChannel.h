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

@interface RBIRCChannel : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSMutableArray *log;
@property (nonatomic, readonly, strong) NSMutableArray *names;
@property (nonatomic, weak) RBIRCServer *server;
@property (nonatomic, copy) NSString *topic;

-(instancetype)initWithName:(NSString *)name;
-(void)logMessage:(RBIRCMessage *)message;

@end
