//
//  RBAppDelegate.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBAppDelegate.h"
#import "SWRevealViewController.h"
#import "RBServerViewController.h"
#import "RBChannelViewController.h"
#import "RBIRCServer.h"

#import "RBConfigurationKeys.h"

@interface RBAppDelegate ()<SWRevealViewControllerDelegate>
@end

@implementation RBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    RBServerViewController *serverVC = [[RBServerViewController alloc] initWithStyle:UITableViewStyleGrouped];
    RBChannelViewController *channelVC = [[RBChannelViewController alloc] init];
    [serverVC setDelegate:channelVC];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:channelVC];
    
    SWRevealViewController *viewController = [[SWRevealViewController alloc] initWithRearViewController:serverVC
                                                                                    frontViewController:nc];
    
    [serverVC setRevealController:viewController];
    [channelVC setRevealController:viewController];
    
    NSData *serverData = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
    if (serverData) {
        NSMutableArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:serverData];
        for (RBIRCServer *server in servers) {
            if (!server.connectOnStartup) {
                [servers removeObject:server];
            }
        }
        serverVC.servers = servers;
    }
    
    self.window.rootViewController = viewController;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
