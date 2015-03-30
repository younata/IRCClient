#import "RBAppDelegate.h"
#import "RBConfigurationKeys.h"

#import <Blindside/Blindside.h>
#import "SpecApplicationModule.h"


#import "SWRevealViewController.h"
#import "RBServerViewController.h"
#import "RBChannelViewController.h"

#import "RBIRCServer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBAppDelegateSpec)

describe(@"RBAppDelegate", ^{
    __block RBAppDelegate *subject;
    __block id<BSInjector> injector;
    __block RBDataManager *dataManager;

    beforeEach(^{
        injector = [Blindside injectorWithModule:[[SpecApplicationModule alloc] init]];
        dataManager = [injector getInstance:[RBDataManager class]];

        [dataManager removeEverything];
        subject = [[RBAppDelegate alloc] init];
        [subject setValue:injector forKey:@"injector"];
    });
    
    afterEach(^{
        [dataManager removeEverything];
    });
    
    describe(@"Initial startup", ^{
        beforeEach(^{
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
            server = [injector getInstance:[RBIRCServer class]];
            [server configureWithHostname:@"test" ssl:YES port:@"6697" nick:@"test" realname:@"test" password:nil];
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
            
            Server *theServer = [dataManager serverWithProperty:server.hostname propertyName:@"host"];
            theServer.name should equal(server.serverName);
            
            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should_not be_empty;
        });
        
        it(@"should launch servers", ^{
            [dataManager serverMatchingIRCServer:server];
            [subject application:nil didFinishLaunchingWithOptions:nil];

            SWRevealViewController *vc = (SWRevealViewController *)subject.window.rootViewController;
            RBServerViewController *ser = (RBServerViewController *)[(UINavigationController *)vc.rearViewController topViewController];
            ser.servers should_not be_empty;
        });
    });
});

SPEC_END
