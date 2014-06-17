//
//  RBDataManager.m
//  IRCClient
//
//  Created by Rachel Brindle on 6/16/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBDataManager.h"

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
    return colors[arc4random_uniform(colors.count)];
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
    NSManagedObjectContext *ctx = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Server" inManagedObjectContext:ctx];
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@", serverName];
    
    NSError *error = nil;
    NSArray *ret = [ctx executeFetchRequest:request error:&error];
    if (!ret) {
        NSLog(@"Error executing fetch request: %@", error);
        return nil;
    }
    
    Server *server = nil;
    
    if (ret.count == 0) {
        server = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:ctx];
        server.name = serverName;
        [ctx save:nil];
    } else {
        server = ret[0];
    }
    
    return server;
}

- (Nick *)nick:(NSString *)name onServer:(Server *)server
{
    NSManagedObjectContext *ctx = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Nick" inManagedObjectContext:ctx];
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND server == %@", name, server];
    
    NSError *error = nil;
    NSArray *ret = [ctx executeFetchRequest:request error:&error];
    if (!ret) {
        NSLog(@"Error executing fetch request: %@", error);
        return nil;
    }
    
    Nick *nick = nil;
    
    if (ret.count == 0) {
        nick = [NSEntityDescription insertNewObjectForEntityForName:@"Nick" inManagedObjectContext:ctx];
        nick.server = server;
        nick.name = name;
        nick.color = randomColor();
        [ctx save:nil];
    } else {
        nick = ret[0];
    }
    
    return nick;
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
