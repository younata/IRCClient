#import "RBReconnectViewController.h"
#import "RBConfigurationKeys.h"
#import "RBIRCServer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBReconnectViewControllerSpec)

describe(@"RBReconnectViewController", ^{
    __block RBReconnectViewController *subject;
    
    id (^userDefaultObject)(NSString *) = ^id(NSString *key) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    };

    beforeEach(^{
        subject = [[RBReconnectViewController alloc] init];
    });
    
    afterEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:Nil forKey:RBConfigServers];
    });
    
    describe(@"initial startup, nothing set", ^{
        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:Nil forKey:RBConfigServers];
            [subject view];
        });
        
        it(@"should not have any default servers to connect to", ^{
            id obj = userDefaultObject(RBConfigServers);
            obj should be_nil;
        });
        
        it(@"should have no cells", ^{
            subject.tableView.visibleCells should be_empty;
        });
    });
    
    describe(@"later startup/when connected", ^{
        __block RBIRCServer *server;
        static NSString *serverName = @"localhost";
        
        void (^saveServer)(RBIRCServer *) = ^(RBIRCServer *s){
            NSArray *array = @[[NSKeyedArchiver archivedDataWithRootObject:s]];
            [[NSUserDefaults standardUserDefaults] setObject:array forKey:RBConfigServers];
        };
        
        beforeEach(^{
            server = [[RBIRCServer alloc] initWithHostname:serverName
                                                       ssl:YES
                                                      port:@"6697"
                                                      nick:@"testnick"
                                                  realname:@"testuser"
                                                  password:nil];
            saveServer(server);
        });
        
        it(@"should have the first cell in a server's section be the server name", ^{
            [subject view];
            UITableViewCell *cell = [subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.textLabel.text should equal(serverName);
            [(UISwitch *)cell.accessoryView isOn] should be_truthy;
        });
        
        it(@"should have the second and later cells in a server's section be channels in the server", ^{
            [server join:@"#test"];
            saveServer(server);
            [subject view];
            UITableViewCell *cell = [subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.textLabel.text should equal(@"#test");
            [(UISwitch *)cell.accessoryView isOn] should be_truthy;
        });
    });
});

SPEC_END
