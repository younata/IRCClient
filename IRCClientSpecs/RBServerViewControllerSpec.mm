#import "RBServerViewController.h"
#import "RBIRCServer.h"
#import "RBIRCChannel.h"
#import "RBServerEditorViewController.h"
#import "RBTextFieldServerCell.h"

#import "RBIRCMessage.h"

#import "RBConfigurationKeys.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBServerViewControllerSpec)

describe(@"RBServerViewController", ^{
    __block RBServerViewController *subject;
    __block RBIRCServer *server;
    
    RBIRCServer *(^newServer)(void) = ^RBIRCServer*{
        RBIRCServer *s = [[RBIRCServer alloc] initWithHostname:@"localhost" ssl:NO port:@"6667" nick:@"testnick" realname:@"testname" password:nil];
        s.serverName = @"test server";
        return s;
    };
    
    BOOL (^serverContainsChannel)(RBIRCServer *, NSString *) = ^BOOL(RBIRCServer *server, NSString *channelName){
        return [server.channels objectForKey:channelName] != nil;
    };

    beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers];
        subject = [[RBServerViewController alloc] init];
        [subject view];
        
        spy_on(subject.tableView);
        spy_on(subject);
    });
    
    it(@"should have 1 default cell, for a new server.", ^{
        [subject numberOfSectionsInTableView:subject.tableView] should equal(1);
        [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(1);
        UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        cell.textLabel.text should equal(@"+ New Server");
    });
    
    it(@"should present an editor view controller when a new server is selected", ^{
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
        subject should have_received(@selector(presentViewController:animated:completion:)).with(Arguments::any([UINavigationController class]), YES, nil);
        subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);
    });
    
    describe(@"disconnects", ^{
        beforeEach(^{
            server = nice_fake_for([RBIRCServer class]);
            server stub_method("nick").and_return(@"testnick");
            server stub_method("nick:").with(Arguments::any([NSString class]));
            server stub_method("oper:password:").with(Arguments::any([NSString class]), Arguments::any([NSString class]));
            server stub_method("quit");
            server stub_method("quit:").with(Arguments::any([NSString class]));
            server stub_method("mode:options:").with(Arguments::any([NSString class]), Arguments::any([NSArray class]));
            server stub_method("kick:target:").with(Arguments::any([NSString class]), Arguments::any([NSString class]));
            server stub_method("kick:target:reason:").with(Arguments::any([NSString class]), Arguments::any([NSString class]), Arguments::any([NSString class]));
            server stub_method("privmsg:contents:").with(Arguments::any([NSString class]), Arguments::any([NSString class]));
            server stub_method("connected").and_return(NO);
            
            subject.servers = [@[server] mutableCopy];
            [subject.tableView reloadData];
        });
        
        it(@"should gray out all cells in this section", ^{
            NSInteger l = [subject.tableView numberOfRowsInSection:0];
            for (int i = 0; i < l; i++) {
                UITableViewCell *cell = [subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                cell.textLabel.textColor should equal([[UIColor darkTextColor] colorWithAlphaComponent:0.5]);
            }
        });
    });
    
    describe(@"server connections", ^{
        __block RBIRCChannel *c;
        beforeEach(^{
            RBIRCServer *s = nice_fake_for([RBIRCServer class]);
            c = [[RBIRCChannel alloc] initWithName:@"#foo"];
            s stub_method("serverName").and_return(@"Test Server");
            s stub_method("channels").and_return(@{@"#foo": c});
            s stub_method("sortedChannelKeys").and_return(@[@"Test Server", RBIRCServerLog, @"#foo"]);
            s stub_method("objectForKeyedSubscript:").and_return(c);
            subject.servers = [@[s] mutableCopy];
            [subject.tableView reloadData];
        });
        
        it(@"should prepend servers to list", ^{
            [subject numberOfSectionsInTableView:subject.tableView] should be_gte(2);
            UITableViewCell *serverCell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            serverCell.textLabel.text should equal(@"Test Server");
            
            UITableViewCell *channelCell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            channelCell.textLabel.text should equal(RBIRCServerLog);
            
            NSInteger i = [subject numberOfSectionsInTableView:subject.tableView];
            i should_not be_lte(1);
            [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i-1]].textLabel.text should equal(@"+ New Server");
        });
        
        it(@"should present a server editor controller when the first cell in a server section is selected", ^{
            NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
            [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
            subject should have_received(@selector(presentViewController:animated:completion:)).with(Arguments::any([UINavigationController class]), YES, nil);
            subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);
        });
        
        it(@"should change the current channel when a channel cell is selected", ^{
            NSIndexPath *ip = [NSIndexPath indexPathForRow:1 inSection:0];
            [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
            subject should_not have_received(@selector(presentViewController:animated:completion:));
            subject.tableView should have_received("deselectRowAtIndexPath:animated:").with(ip, Arguments::anything);

        });
    });
    
    describe(@"new channel cell", ^{
        beforeEach(^{
            server = newServer();
            
            spy_on(server);
            
            [subject.servers addObject:server];
            [subject.tableView reloadData];
            [subject view];
        });
        
        it(@"should be a member of RBTextFieldServerCell", ^{
            UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            cell should be_instance_of([RBTextFieldServerCell class]);
        });
        
        describe(@"joining", ^{
            static NSString *channelName = @"#foo";
            static NSString *userName = @"foo";
            
            void (^joinChannel)(NSString *) = ^(NSString *channel){
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers];
                RBTextFieldServerCell *cell;
                for (UITableViewCell *c in subject.tableView.visibleCells) {
                    if (![c isKindOfClass:[RBTextFieldServerCell class]])
                        continue;
                    cell = (RBTextFieldServerCell*)c;
                }
                cell.textField.text = channel;
                [subject textFieldShouldReturn:cell.textField];
            };
            
            it(@"should actually join", ^{
                joinChannel(channelName);
                server should have_received("join:").with(channelName);
                server.channels.count should be_gte(1);
                NSInteger i = server.channels.count;
                serverContainsChannel(server, channelName) should be_truthy;
                
                [(id<CedarDouble>)server reset_sent_messages];
                
                joinChannel(userName);
                server should_not have_received("join:").with(userName);
                server.channels.count should equal(i);
                serverContainsChannel(server, userName) should be_truthy;
            });
            
            it(@"should save the change to the internal database", ^{
                joinChannel(channelName);
                
                NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
                d should_not be_nil;
                NSMutableArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                servers.count should be_gte(1);
                BOOL actuallyDidSave = NO;
                for (RBIRCServer *s in servers) {
                    actuallyDidSave = serverContainsChannel(s, channelName);
                    if (actuallyDidSave)
                        break;
                }
                actuallyDidSave should be_truthy;
                
                [(id<CedarDouble>)server reset_sent_messages];
                
                joinChannel(userName);
                d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
                d should_not be_nil;
                servers = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                servers.count should be_gte(1);
                actuallyDidSave = NO;
                for (RBIRCServer *s in servers) {
                    actuallyDidSave = serverContainsChannel(s, userName);
                    if (actuallyDidSave)
                        break;
                }
                actuallyDidSave should be_truthy;
            });
        });
    });
    
    describe(@"Parting a channel", ^{
        static NSString *chName = @"#foo";
        beforeEach(^{
            server = newServer();
            
            RBIRCChannel *channel = [[RBIRCChannel alloc] initWithName:chName];
            [server.channels setObject:channel forKey:chName];
            
            NSMutableArray *arr = [@[server] mutableCopy];
            NSData *d = [NSKeyedArchiver archivedDataWithRootObject:arr];
            [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
            subject.servers = arr;
            [subject.tableView reloadData];
            NSIndexPath *indexPath = nil;
            for (int i = 1; i < [subject tableView:subject.tableView numberOfRowsInSection:0]; i++) {
                indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:indexPath];
                if ([cell.textLabel.text isEqualToString:chName]) {
                    break;
                }
                indexPath = nil;
            }
            if (indexPath) {
                [subject tableView:subject.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
            }
        });
        
        it(@"should remove the channel cell from the view", ^{
            NSArray *cells = [subject.tableView visibleCells];
            BOOL containsChannel = NO;
            for (UITableViewCell *cell in cells) {
                containsChannel = [cell.textLabel.text isEqualToString:chName];
                if (containsChannel) {
                    break;
                }
            }
            containsChannel should be_falsy;
        });
        
        it(@"should remove the channel from the internal database", ^{
            NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
            d should_not be_nil;
            NSMutableArray *servers = [NSKeyedUnarchiver unarchiveObjectWithData:d];
            servers.count should be_gte(1);
            BOOL actuallyDidSave = YES;
            for (RBIRCServer *s in servers) {
                actuallyDidSave = serverContainsChannel(s, chName);
                if (actuallyDidSave)
                    break;
            }
            actuallyDidSave should be_falsy;
        });
    });
    
    describe(@"Unread message count", ^{
        NSIndexPath *ip = [NSIndexPath indexPathForRow:2 inSection:0];
        
        static NSString *chName = @"#foo";
        
        beforeEach(^{
            server = newServer();
            
            RBIRCChannel *channel = [[RBIRCChannel alloc] initWithName:chName];
            [server.channels setObject:channel forKey:chName];
            
            NSMutableArray *arr = [@[server] mutableCopy];
            subject.servers = arr;
            [subject.tableView reloadData];
            
            [subject tableView:subject.tableView didSelectRowAtIndexPath:ip];
        });
        
        it(@"should not display a number when unread messages is 0", ^{
            UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:ip];
            [cell.textLabel.text hasPrefix:@"[0]"] should be_falsy;
        });
        
        it(@"should display a number when unread messages is not 0", ^{
            [subject tableView:subject.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            NSMutableArray *servers = subject.servers;
            RBIRCServer *server = servers[0];
            NSString *msg = @":ik!iank@hide-1664EBC6.iank.org PRIVMSG #foo :how are you?";
            
            RBIRCMessage *message = [[RBIRCMessage alloc] initWithRawMessage:msg onServer:server];
            RBIRCChannel *channel = server[message.targets[0]];
            [channel logMessage:message];
            
            NSNotification *note = [[NSNotification alloc] initWithName:RBIRCServerHandleMessage object:server userInfo:@{@"message": message}];
            [subject handleNotification:note]; // directly doing this through RBIRCServer's receivedString: can cause an unallocated RBIRCChannelViewController to crash...
            
            UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:ip];
            [cell.textLabel.text hasPrefix:@"[1]"] should be_truthy;
        });
    });
});

SPEC_END
