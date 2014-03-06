#import "RBScriptingService.h"
#import "RBConfigurationKeys.h"

#import "RBIRCChannel.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

#import "RBColorScheme.h"

#import "RBServerViewController.h"

#import "RBScript.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBScriptingServiceSpec)

describe(@"RBScriptingService", ^{
    __block RBScriptingService *subject;
    
    beforeEach(^{
        subject = [RBScriptingService sharedInstance];
    });
    
    [[RBScriptingService sharedInstance] loadScripts];
    
    void (^checkIfLoaded)(NSString *) = ^(NSString *k) {
        BOOL isLoaded = NO;
        for (RBScript *script in subject.scriptSet) {
            if ([NSStringFromClass([script class]) isEqualToString:k]) {
                isLoaded = YES;
                break;
            }
        }
        isLoaded should be_truthy;
    };
    
    it(@"should not auto-load objects", ^{
        subject.scriptSet.count should equal(0);
    });
    
    it(@"should have at least one script class", ^{
        subject.scriptDict.count should be_gte(1);
    });
    
    describe(@"Hilight script", ^{
        NSString *key = @"Highlight";
        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:key];
            [subject runEnabledScripts];
        });
        
        afterEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:key];
        });
        
        it(@"should be loaded", ^{
            checkIfLoaded(key);
        });
        
        it(@"should highlight your nick only", ^{
            RBIRCServer *server = nice_fake_for([RBIRCServer class]);
            
            server stub_method("nick").and_return(@"You");
            
            RBIRCMessage *message = [[RBIRCMessage alloc] init];
            message.command = IRCMessageTypePrivmsg;
            message.message = @"hi You";
            message.targets = [@[@"#test"] mutableCopy];
            message.from = @"ik";
            
            NSAttributedString *str = message.attributedMessage;
            
            RBIRCChannel *channel = fake_for([RBIRCChannel class]);
            channel stub_method("server").and_return(server);
            
            [subject channel:channel didLogMessage:message];
            NSAttributedString *newStr = message.attributedMessage;
            str should_not equal(newStr);
            NSLog(@"Highlighted message: %@", newStr);
        });
    });
    
    describe(@"Reconnect script", ^{
        __block RBServerViewController *svc;
        __block RBIRCServer *server;
        NSString *key = @"ServerReconnectButton";
        
        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:key];
            [subject runEnabledScripts];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigServers];
            
            server = fake_for([RBIRCServer class]);
            server stub_method("serverName").and_return(@"blah");
            server stub_method("connected").and_return(YES);
            server stub_method("addDelegate:");
            server stub_method("connect");
            server stub_method("quit");
            server stub_method("sortedChannelKeys").and_return(@[@"blah", RBIRCServerLog]);
            server stub_method(@selector(objectForKeyedSubscript:)).and_return([[RBIRCChannel alloc] initWithName:RBIRCServerLog]);
            
            svc = [[RBServerViewController alloc] init];
            svc.servers = [@[server] mutableCopy];
            [svc.tableView reloadData];
        });
        
        afterEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:key];
        });
        
        it(@"should be loaded", ^{
            checkIfLoaded(key);
        });
        
        it(@"should add a 'reconnect' button as the accessory view of the server cell", ^{
            UITableViewCell *tvc = [svc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            tvc.accessoryView should be_instance_of([UIButton class]);
        });
        
        it(@"should quit then reconnect when the button is pressed", ^{
            UITableViewCell *tvc = [svc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            UIButton *b = (UIButton *)tvc.accessoryView;
            b should_not be_nil;
            [b sendActionsForControlEvents:UIControlEventTouchUpInside];
            
            server should have_received("quit");
            server should have_received("connect");
        });
    });
    
    describe(@"inline images", ^{
        NSString *key = @"InlineImages";
        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:key];
            [subject runEnabledScripts];
        });
        
        afterEach(^{
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:key];
        });
        
        it(@"should be loaded", ^{
            checkIfLoaded(key);
        });
        
        describe(@"SFW images", ^{
            it(@"should append a text attachment for messages with links to images", ^{
                RBIRCMessage *message = [[RBIRCMessage alloc] init];
                message.timestamp = [NSDate date];
                message.from = @"ik";
                message.message = @"http://i.imgur.com/hjw7z6A.jpg"; // Is an actual image.
                NSLog(@"%@", message.attributedMessage);
                NSAttributedString *blah = message.attributedMessage;
                [[RBScriptingService sharedInstance] server:nil didReceiveMessage:message];
                NSLog(@"%@", message.attributedMessage);
                message.attributedMessage should_not equal(blah);
            });
        });
    });
});

SPEC_END
