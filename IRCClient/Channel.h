//
//  Channel.h
//  IRCClient
//
//  Created by Rachel Brindle on 12/24/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Server;

@interface Channel : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * log;
@property (nonatomic, retain) Server *server;

@end
