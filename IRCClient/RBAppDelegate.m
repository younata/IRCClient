//
//  RBAppDelegate.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Blindside/Blindside.h>
#import <RESideMenu/RESideMenu.h>

#import "RBAppDelegate.h"
#import "SWRevealViewController.h"
#import "RBServerViewController.h"
#import "RBChannelViewController.h"
#import "RBNameViewController.h"
#import "RBServerEditorViewController.h"
#import "RBIRCServer.h"

#import "RBHelp.h"
#import "RBColorScheme.h"

#import "RBConfigurationKeys.h"

#import "RBDataManager.h"
#import "Server.h"

#import "ApplicationModule.h"

@interface RBAppDelegate ()<SWRevealViewControllerDelegate>
@property (nonatomic) UIBackgroundTaskIdentifier taskIdentifier;
@property (nonatomic, strong) UIWindow *secondWindow;
@property (nonatomic, strong) id<BSInjector> injector;
@property (nonatomic, strong) RBDataManager *dataManager;
@end

@implementation RBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    self.injector = [Blindside injectorWithModule:[[ApplicationModule alloc] init]];
    
    [UIBarButtonItem appearance].tintColor = [RBColorScheme primaryColor];
    
    self.taskIdentifier = UIBackgroundTaskInvalid;
    
    [self checkForExistingScreenAndInitializeIfPresent];
    [self setUpScreenConnectionNotificationHandlers];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[RBColorScheme primaryColor]] forKey:RBHelpTintColor];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[RBColorScheme secondaryColor]] forKey:RBHelpLinkColor];
    
    RBServerViewController *serverVC = [self.injector getInstance:[RBServerViewController class]];
    RBChannelViewController *channelVC = [self.injector getInstance:[RBChannelViewController class]];
    
    UINavigationController *channelViewController = [[UINavigationController alloc] initWithRootViewController:channelVC];
    UINavigationController *serverViewController = [[UINavigationController alloc] initWithRootViewController:serverVC];
    RBNameViewController *namesViewController = [self.injector getInstance:[RBNameViewController class]];

    RESideMenu *sideMenuController = [[RESideMenu alloc] initWithContentViewController:channelViewController
                                                      leftMenuViewController:serverViewController
                                                     rightMenuViewController:namesViewController];

    NSData *serverData = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBConfigKeyServers"];

    self.dataManager = [self.injector getInstance:[RBDataManager class]];

    if (serverData) {
        NSMutableArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:serverData];
        for (RBIRCServer *server in servers) {
            [[[self.dataManager serverMatchingIRCServer:server] managedObjectContext] save:nil];
        }
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"RBConfigKeyServers"];
    }
    
    [self setServersForServerVC:serverVC];
    
    self.window.rootViewController = sideMenuController;
    
    return YES;
}

- (void)setServersForServerVC:(RBServerViewController *)svc
{
    NSArray *servers = [self.dataManager servers];
    if ([servers count] != 0) {
        NSMutableArray *serversList = [[NSMutableArray alloc] initWithCapacity:servers.count];
        for (Server *server in servers) {
            RBIRCServer *ircServer = [self.injector getInstance:[RBIRCServer class]];
            [ircServer configureWithServer:server];
            [serversList addObject:ircServer];
        }
        svc.servers = serversList;
    }
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

#pragma mark - Secondary Screen (airplay support!)

-(void)initializeSecondScreen
{
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[[RBChannelViewController alloc] init]];
    
    self.secondWindow.rootViewController = nc;
}

-(void)checkForExistingScreenAndInitializeIfPresent
{
    if ([[UIScreen screens] count] > 1) {
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];
        CGRect screenBounds = secondScreen.bounds;
        
        self.secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        self.secondWindow.screen = secondScreen;
        
        [self initializeSecondScreen];
        self.secondWindow.hidden = NO;
    }
}

-(void)setUpScreenConnectionNotificationHandlers
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleScreenDidConnectNotification:) name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleScreenDidDisconnectNotification:) name:UIScreenDidDisconnectNotification object:nil];
}

-(void)handleScreenDidConnectNotification:(NSNotification *)note
{
    UIScreen *newScreen = [note object];
    CGRect screenBounds = newScreen.bounds;
    
    if (!self.secondWindow) {
        self.secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        self.secondWindow.screen = newScreen;
        [self initializeSecondScreen];
        self.secondWindow.hidden = NO;
    }
}

-(void)handleScreenDidDisconnectNotification:(NSNotification *)note
{
    if (self.secondWindow) {
        self.secondWindow.hidden = YES;
        self.secondWindow = nil;
    }
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
    
    [self setServersForServerVC:svc];
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
