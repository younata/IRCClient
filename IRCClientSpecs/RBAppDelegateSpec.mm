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
        subject = [[RBAppDelegate alloc] init];
    });
    
    afterEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers]; // FIXME
    });
    
    describe(@"Initial startup", ^{
        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers]; // FIXME
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
            NSData *d = [NSKeyedArchiver archivedDataWithRootObject:@[server]];
            [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
            [subject application:nil didFinishLaunchingWithOptions:nil];
        });
        
        it(@"should launch servers", ^{
            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should_not be_empty;
        });
    });
});

SPEC_END
