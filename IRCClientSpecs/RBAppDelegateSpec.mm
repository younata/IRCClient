#import "RBAppDelegate.h"
#import "RBConfigurationKeys.h"

#import "SWRevealViewController.h"
#import "RBServerViewController.h"
#import "RBChannelViewController.h"

#import "RBIRCServer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBAppDelegateSpec)

describe(@"RBAppDelegate", ^{
    __block RBAppDelegate *subject;

    beforeEach(^{
        [[RBDataManager sharedInstance] removeEverything];
        subject = [[RBAppDelegate alloc] init];
    });
    
    afterEach(^{
        [[RBDataManager sharedInstance] removeEverything];
    });
    
    describe(@"Initial startup", ^{
        beforeEach(^{
            [[RBDataManager sharedInstance] removeEverything];
            [subject application:nil didFinishLaunchingWithOptions:nil];
        });
        
        it(@"should not launch servers", ^{
            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should be_empty;
        });
    });
    
    describe(@"Subsequent startups", ^{
        __block RBIRCServer *server;
        
        beforeEach(^{
            server = [[RBIRCServer alloc] initWithHostname:@"test" ssl:YES port:@"6697" nick:@"test" realname:@"test" password:nil];
            server.serverName = @"test";
            server.readStream = nice_fake_for([NSInputStream class]);
            server.writeStream = nice_fake_for([NSOutputStream class]);
        });
        
        it(@"should convert from NSUserDefaults persistance to core data persistence", ^{
            NSData *d = [NSKeyedArchiver archivedDataWithRootObject:@[server]];
            NSString *key = @"RBConfigKeyServers";
            [[NSUserDefaults standardUserDefaults] setObject:d forKey:key];
            [subject application:nil didFinishLaunchingWithOptions:nil];
            
            [[NSUserDefaults standardUserDefaults] objectForKey:key] should be_nil;
            
            Server *theServer = [[RBDataManager sharedInstance] serverWithProperty:server.hostname propertyName:@"host"];
            theServer.name should equal(server.serverName);
            
            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should_not be_empty;
        });
        
        it(@"should launch servers", ^{
            [[RBDataManager sharedInstance] serverMatchingIRCServer:server];
            [subject application:nil didFinishLaunchingWithOptions:nil];

            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should_not be_empty;
        });
    });
});

SPEC_END
