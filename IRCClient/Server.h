//
//  Server.h
//  IRCClient
//
//  Created by Rachel Brindle on 6/16/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Server : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSSet *nicks;
@end

@interface Server (CoreDataGeneratedAccessors)

- (void)addNicksObject:(NSManagedObject *)value;
- (void)removeNicksObject:(NSManagedObject *)value;
- (void)addNicks:(NSSet *)values;
- (void)removeNicks:(NSSet *)values;

@end
