//
//  RBIRCChannel.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RBIRCMessage;

@interface RBIRCChannel : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSMutableArray *log;

-(instancetype)initWithName:(NSString *)name;
-(void)logMessage:(RBIRCMessage *)message;

@end
