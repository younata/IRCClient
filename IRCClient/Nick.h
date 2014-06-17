//
//  Nick.h
//  IRCClient
//
//  Created by Rachel Brindle on 6/16/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Server;

@interface Nick : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) Server *server;

@end
