#import "RBReconnectViewController.h"
#import "RBConfigurationKeys.h"
#import "RBIRCServer.h"
#import "RBIRCChannel.h"

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
        subject.servers = [[NSMutableArray alloc] init];
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
        
        void (^saveServer)(RBIRCServer *) = ^(RBIRCServer *serv){
            subject.servers = [@[serv] mutableCopy];
        };
        
        beforeEach(^{
            server = [[RBIRCServer alloc] initWithHostname:serverName
                                                       ssl:YES
                                                      port:@"6697"
                                                      nick:@"testnick"
                                                  realname:@"testuser"
                                                  password:nil];
            server.serverName = serverName;
            saveServer(server);
        });
        
        it(@"should have at least one section and at least one row in the first section", ^{
            [subject.tableView.dataSource numberOfSectionsInTableView:subject.tableView] should be_gte(1);
            [subject.tableView.dataSource tableView:subject.tableView numberOfRowsInSection:0] should be_gte(1);
            server.connectOnStartup should be_truthy;
        });
        
        it(@"should have the first cell in a server's section be the server name", ^{
            [subject view];
            UITableViewCell *cell = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell should_not be_nil;
            cell.textLabel.text should equal(serverName);
            cell.accessoryView should be_instance_of([UISwitch class]);
            [(UISwitch *)cell.accessoryView isOn] should equal(server.connectOnStartup);
        });
        
        it(@"should have the second and later cells in a server's section be channels in the server", ^{
            [server join:@"#test"];
            saveServer(server);
            [subject view];
            UITableViewCell *cell = [subject.tableView.dataSource tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.textLabel.text should equal(@"#test");
            cell.accessoryView should be_instance_of([UISwitch class]);
            [(UISwitch *)cell.accessoryView isOn] should be_truthy;
        });
        
        it(@"should save changes", ^{
            [server join:@"#test"];
            saveServer(server);
            [subject view];
            for (UITableViewCell *cell in subject.tableView.visibleCells) {
                if ([cell.textLabel.text isEqualToString:@"#test"]) {
                    UISwitch *s = (UISwitch *)cell.accessoryView;
                    [s setOn:NO];
                    [s sendActionsForControlEvents:UIControlEventValueChanged];
                }
            }
            [subject save];
            NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
            NSArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:d];
            RBIRCServer *s = servers.firstObject;
            [(RBIRCChannel *)s.channels[@"#test"] connectOnStartup] should be_falsy;
        });
    });
});

SPEC_END
