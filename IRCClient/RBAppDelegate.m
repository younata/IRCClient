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
#import "RBNameViewController.h"
#import "RBServerEditorViewController.h"
#import "RBIRCServer.h"

#import "RBHelp.h"
#import "RBColorScheme.h"

#import "RBScriptingService.h"
#import "RBConfigurationKeys.h"

@interface RBAppDelegate ()<SWRevealViewControllerDelegate>
@property (nonatomic) UIBackgroundTaskIdentifier taskIdentifier;
@end

@implementation RBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    self.taskIdentifier = UIBackgroundTaskInvalid;
    
    [[RBScriptingService sharedInstance] runEnabledScripts];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[RBColorScheme primaryColor]] forKey:RBHelpTintColor];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[RBColorScheme secondaryColor]] forKey:RBHelpLinkColor];
    
    RBServerViewController *serverVC = [[RBServerViewController alloc] initWithStyle:UITableViewStyleGrouped];
    RBChannelViewController *channelVC = [[RBChannelViewController alloc] init];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:channelVC];
    UINavigationController *otherNC = [[UINavigationController alloc] initWithRootViewController:serverVC];
    RBNameViewController *names = [[RBNameViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    SWRevealViewController *viewController = [[SWRevealViewController alloc] initWithRearViewController:otherNC
                                                                                    frontViewController:nc];
    viewController.rightViewController = names;
    
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

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] hasPrefix:@"irc"] || [[url scheme] hasPrefix:@"rirc"]) {
        NSString *username = [url user];
        NSString *password = [url password];
        NSString *hostname = [url host];
        NSString *port = [[url port] stringValue];
        NSNumber *useSSL = @(NO);
        if ([[url scheme] hasSuffix:@"s"]) {
            useSSL = @(YES);
            if (!port) {
                port = @"6697";
            }
        } else {
            if (!port) {
                port = @"6667";
            }
        }
        
        if (self.window.rootViewController == nil) {
            [self application:application didFinishLaunchingWithOptions:nil];
        }
        
        RBServerViewController *serverVC = (RBServerViewController *)[(UINavigationController *)[(SWRevealViewController *)self.window.rootViewController rearViewController] topViewController];
        NSDictionary *options = @{@"username": username,
                                  @"password": password,
                                  @"port": port,
                                  @"hostname": hostname,
                                  @"ssl": useSSL};
        RBServerEditorViewController *editorVC = [serverVC editorViewControllerWithOptions:options];
        [serverVC presentViewController:editorVC animated:YES completion:nil];
        
        return YES;
    }
    return NO;
}

-(NSArray *)servers
{
    SWRevealViewController *rvc = (SWRevealViewController *)self.window.rootViewController;
    RBServerViewController *svc = (RBServerViewController *)[(UINavigationController *)rvc.rearViewController topViewController];
    return svc.servers;
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
    
    SWRevealViewController *rvc = (SWRevealViewController *)self.window.rootViewController;
    RBChannelViewController *cvc = (RBChannelViewController *)[(UINavigationController *)rvc.frontViewController topViewController];
    RBServerViewController *svc = (RBServerViewController *)[(UINavigationController *)rvc.rearViewController topViewController];
    
    self.taskIdentifier = [application beginBackgroundTaskWithName:@"server background task" expirationHandler:^{
        if ([application applicationState] == UIApplicationStateBackground) {
            for (RBIRCServer *server in self.servers) {
                [server quit];
            }
            
            svc.servers = nil;
            [cvc disconnect];
        }
        [[UIApplication sharedApplication] endBackgroundTask:self.taskIdentifier];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    for (RBIRCServer *server in self.servers) {
        if (server.connected) {
            return;
        }
    }
    
    SWRevealViewController *rvc = (SWRevealViewController *)self.window.rootViewController;
    RBServerViewController *svc = (RBServerViewController *)[(UINavigationController *)rvc.rearViewController topViewController];
    
    NSData *serverData = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
    if (serverData) {
        NSMutableArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:serverData];
        for (RBIRCServer *server in servers) {
            if (!server.connectOnStartup) {
                [servers removeObject:server];
            }
        }
        svc.servers = servers;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    for (RBIRCServer *server in self.servers) {
        [server quit];
    }
}

@end
