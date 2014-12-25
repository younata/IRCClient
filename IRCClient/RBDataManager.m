//
//  RBDataManager.m
//  IRCClient
//
//  Created by Rachel Brindle on 6/16/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBDataManager.h"

#import "RBIRCServer.h"
#import "RBIRCChannel.h"

@interface RBDataManager ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void)saveContext;
-(NSString *)applicationDocumentsDirectory;

@end

UIColor *randomColor()
{
    NSArray *colors = @[[UIColor grayColor],
                        [UIColor redColor],
                        [UIColor greenColor],
                        [UIColor blueColor],
                        [UIColor cyanColor],
                        [UIColor magentaColor],
                        [UIColor orangeColor],
                        [UIColor purpleColor],
                        [UIColor brownColor]
                        ];
    return colors[arc4random_uniform((int)colors.count)];
}

@implementation RBDataManager

+ (RBDataManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    static RBDataManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[RBDataManager alloc] init];
    });
    return instance;
}

- (UIColor *)colorForNick:(NSString *)nick onServer:(NSString *)serverName
{
    Server *server = [self serverForServerName:serverName];
    Nick *name = [self nick:nick onServer:server];
    return name.color;
}

- (Server *)serverForServerName:(NSString *)serverName
{
    NSArray *ret = [self entities:@"Server" matchingPredicate:[NSPredicate predicateWithFormat:@"name == %@", serverName]];
    
    Server *server = nil;
    
    if (ret.count == 0) {
        server = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:[self managedObjectContext]];
        server.name = serverName;
        [server.managedObjectContext save:nil];
    } else {
        server = ret[0];
    }
    
    return server;
}

- (Server *)serverWithProperty:(id)property propertyName:(NSString *)propertyName
{
    return (Server *)[self managedObject:@"Server" withProperty:property propertyName:propertyName];
}

- (Server *)serverMatchingIRCServer:(RBIRCServer *)ircServer
{
    Server *server = [self serverWithProperty:ircServer.hostname propertyName:@"host"];
    server.name = ircServer.hostname;
    server.nick = ircServer.nick;
    server.port = ircServer.port;
    server.realname = ircServer.realname;
    server.password = ircServer.password;
    server.ssl = @(ircServer.useSSL);
    NSMutableSet *existingChannels = [server.channels mutableCopy];
    NSMutableSet *newChannels = [[NSMutableSet alloc] initWithCapacity:ircServer.channels.allValues.count];
    for (RBIRCChannel *channel in ircServer.channels.allValues) {
        Channel *theChannel = [self channelMatchingIRCChannel:channel];
        [newChannels addObject:theChannel];
    }
    NSMutableSet *toAdd = [newChannels mutableCopy];
    [toAdd minusSet:existingChannels]; // Removes every channel in toAdd that's wasn't in server previously
    [existingChannels minusSet:newChannels]; // removes every channel in existingChannels that isn't currently in ircServer
    [server removeChannels:existingChannels]; // removes from the Server object every channel that isn't in the ircServer object
    [server addChannels:toAdd]; // adds to the Server object every new channel.
    for (Channel *channel in existingChannels) {
        [[channel managedObjectContext] deleteObject:channel];
    }
    
    return server;
}

- (Channel *)channelMatchingIRCChannel:(RBIRCChannel *)ircChannel
{
    Server *server = [self serverMatchingIRCServer:ircChannel.server];
    NSArray *channels = [self entities:@"Channel" matchingPredicate:[NSPredicate predicateWithFormat:@"name == %@ AND server == %@", ircChannel.name, server]];
    
    Channel *channel = nil;
    
    if (channels.count == 0) {
        channel = [NSEntityDescription insertNewObjectForEntityForName:@"Nick" inManagedObjectContext:[self managedObjectContext]];
        channel.server = server;
        channel.name = ircChannel.name;
        [channel.managedObjectContext save:nil];
    } else {
        channel = channels[0];
    }
    
    return channel;
}

- (Nick *)nick:(NSString *)name onServer:(Server *)server
{
    NSArray *nicks = [self entities:@"Nick" matchingPredicate:[NSPredicate predicateWithFormat:@"name == %@ AND server == %@", name, server]];
    
    Nick *nick = nil;
    
    if (nicks.count == 0) {
        nick = [NSEntityDescription insertNewObjectForEntityForName:@"Nick" inManagedObjectContext:[self managedObjectContext]];
        nick.server = server;
        nick.name = name;
        nick.color = randomColor();
        [nick.managedObjectContext save:nil];
    } else {
        nick = nicks[0];
    }
    
    return nick;
}

- (NSArray *)servers
{
    return [self entities:@"Server" matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSManagedObject *)managedObject:(NSString *)objectName withProperty:(id)property propertyName:(NSString *)propertyName
{
    NSArray *ret = [self entities:objectName matchingPredicate:[NSPredicate predicateWithFormat:@"%@ == %@", propertyName, property]];
    
    NSManagedObject *val = nil;
    
    if (ret.count == 0) {
        val = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:[self managedObjectContext]];
        [val setValue:property forKey:propertyName];
        [val.managedObjectContext save:nil];
    } else {
        val = ret.firstObject;
    }
    
    return val;
}

- (NSArray *)entities:(NSString *)entity matchingPredicate:(NSPredicate *)predicate
{
    NSManagedObjectContext *ctx = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:entity inManagedObjectContext:ctx];
    request.predicate = predicate;
    
    NSError *error = nil;
    NSArray *ret = [ctx executeFetchRequest:request error:&error];
    if (!ret) {
        NSLog(@"Error executing fetch request: %@", error);
        return nil;
    }
    
    return ret;
}

-(NSManagedObjectContext *)managedObjectContext
{
    static NSManagedObjectContext *ctx = nil;
    if (ctx != nil) {
        return ctx;
    }
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        ctx = [[NSManagedObjectContext alloc] init];
        [ctx setPersistentStoreCoordinator:coordinator];
    }
    return ctx;
}

-(NSManagedObjectModel *)managedObjectModel
{
    static NSManagedObjectModel *model = nil;
    if (model != nil) {
        return model;
    }
    
    model = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return model;
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    static NSPersistentStoreCoordinator *coord = nil;
    if (coord != nil) {
        return coord;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"LocationLogger.sqlite"]];
    NSError *err = nil;
    
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&err]) {
        NSLog(@"Error adding persistent store type: %@", err);
    }
    
    return coord;
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
