#import "RBChannelViewController.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "RBIRCChannel.h"

#import "RBServerViewController.h"

#import "UIActionSheet+allButtonTitles.h"

#import "UITableView+Scroll.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBChannelViewControllerSpec)

describe(@"RBChannelViewController", ^{
    __block RBChannelViewController *subject;
    __block RBIRCServer *server;
    
    NSString *channel = @"#foo";

    beforeEach(^{
        subject = [[RBChannelViewController alloc] init];
        subject.revealController = nice_fake_for([SWRevealViewController class]);
        [subject view];
        
        subject.channel = channel;
        
        spy_on(subject);

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
        server stub_method("sendCommand:").with(Arguments::any([NSString class]));
        subject.server = server;
    });
    
    afterEach(^{
        subject = nil; // really cedar?
    });
    
    describe(@"text input", ^{
        beforeEach(^{
            server stub_method("connected").and_return(YES);
        });
        
        describe(@"easily input commands", ^{
            beforeEach(^{
                // UIActionSheets have exceptions with this... :/
                @try {
                    [subject.inputCommands sendActionsForControlEvents:UIControlEventAllTouchEvents];
                } @catch (NSException *e) {
                    ; // nope
                }
            });
            
            it(@"should have received showInputCommands", ^{
                subject should have_received("showInputCommands");
            });
            
            it(@"should have a button which brings up a menu for possible commands", ^{
                subject.actionSheet should_not be_nil;
            });
            
            it(@"should have a button for most of the commands listed in IRCMessageType", ^{
                NSArray *arr = [subject.actionSheet allButtonTitles];
                for (NSString *str in @[@"notice", @"mode", @"kick", @"topic", @"nick", @"quit", @"action", @"ctcp"]) {
                    arr should contain(str);
                }
            });
            
            it(@"should prepend text to the input field when a button is pressed", ^{
                NSString *str = [subject.actionSheet buttonTitleAtIndex:3];
                [subject actionSheet:subject.actionSheet clickedButtonAtIndex:3];
                [subject.input.text hasPrefix:[NSString stringWithFormat:@"/%@", str]] should be_truthy;
            });
            
            it(@"should prepend /me to the input field for actions", ^{
                for (int i = 0; i < [subject.actionSheet numberOfButtons]; i++) {
                    if ([[subject.actionSheet buttonTitleAtIndex:i] isEqualToString:@"action"]) {
                        [subject actionSheet:subject.actionSheet clickedButtonAtIndex:i];
                        [subject.input.text hasPrefix:@"/me"] should be_truthy;
                    }
                }
            });
            
            it(@"should not prepend text if cancel is pressed", ^{
                [subject actionSheet:subject.actionSheet clickedButtonAtIndex:subject.actionSheet.cancelButtonIndex];
                
                subject.input.text.length should equal(0);
            });
            
        });
        
        describe(@"CTCP", ^{
            NSString *delim = [NSString stringWithFormat:@"%c", 1];

            NSString *(^sendCTCP)(NSString *, NSString *) = ^NSString *(NSString *target, NSString *msg){
                return [NSString stringWithFormat:@"PRIVMSG %@ :%@%@%@\r\n", target, delim, msg, delim];
            };
            
            void (^addTextAndSend)(NSString *) = ^(NSString *msg){
                subject.input.text = msg;
                [subject textViewShouldReturn:subject.input];
            };
            it(@"should ACTION", ^{
                addTextAndSend(@"/me codes.");
                server should have_received("sendCommand:").with(sendCTCP(subject.channel, @"ACTION codes."));
            });
            
            it(@"should FINGER", ^{
                addTextAndSend(@"/ctcp finger ik");
                server should have_received("sendCommand:").with(sendCTCP(@"ik", @"FINGER"));
            });
            
            it(@"should arbitrary CTCP", ^{
                addTextAndSend(@"/ctcp arbitraryctcpcommand ik");
                server should have_received("sendCommand:").with(sendCTCP(@"ik", [@"arbitraryctcpcommand" uppercaseString]));
            });
            
            it(@"should PING", ^{
                addTextAndSend(@"/ctcp ping ik");
                server should have_received("sendCommand:").with(Arguments::any([NSString class]));
            });
        });
        
        describe(@"basic commands", ^{
            it(@"should nick", ^{
                subject.input.text = @"/nick";
                [subject textViewShouldReturn:subject.input];
                server should_not have_received("nick:");
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/nick foobar";
                [subject textViewShouldReturn:subject.input];
                server should have_received("nick:").with(@"foobar");
            });
            
            it(@"should oper", ^{
                subject.input.text = @"/oper foo";
                [subject textViewShouldReturn:subject.input];
                server should_not have_received("oper:password:");
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/oper foo bar";
                [subject textViewShouldReturn:subject.input];
                server should have_received("oper:password:").with(@"foo", @"bar");
            });
            
            it(@"should quit", ^{
                subject.input.text = @"/quit";
                [subject textViewShouldReturn:subject.input];
                server should have_received("quit:").with(subject.server.nick);
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/quit foobar";
                [subject textViewShouldReturn:subject.input];
                server should have_received("quit:").with(@"foobar");
            });
            
            it(@"should mode", ^{
                subject.input.text = @"/mode +b ik";
                [subject textViewShouldReturn:subject.input];
                server should have_received("mode:options:").with(channel, @[@"+b", @"ik"]);
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/mode +b ik";
                [subject textViewShouldReturn:subject.input];
                server should have_received("mode:options:").with(channel, @[@"+b", @"ik"]);
            });
            
            it(@"should kick", ^{
                subject.input.text = @"/kick ik";
                [subject textViewShouldReturn:subject.input];
                server should have_received("kick:target:reason:").with(channel, @"ik", subject.server.nick);
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/kick ik reason";
                [subject textViewShouldReturn:subject.input];
                server should have_received("kick:target:reason:").with(channel, @"ik", @"reason");
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/kick";
                [subject textViewShouldReturn:subject.input];
                server should_not have_received("kick:target:");
                server should_not have_received("kick:target:reason:");
            });
            
            it(@"should privmsg", ^{
                subject.input.text = @"hello world";
                [subject textViewShouldReturn:subject.input];
                server should have_received("privmsg:contents:").with(channel, @"hello world");
            });
            
            it(@"should privmsg as /msg", ^{
                subject.input.text = @"/msg #foo hello world";
                [subject textViewShouldReturn:subject.input];
                server should have_received("privmsg:contents:").with(channel, @"hello world");
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/msg ik hello world";
                [subject textViewShouldReturn:subject.input];
                server should have_received("privmsg:contents:").with(@"ik", @"hello world");
            });
            
            it(@"should notice", ^{
                subject.input.text = @"/notice #foo hello world";
                [subject textViewShouldReturn:subject.input];
                server should have_received(@selector(notice:contents:)).with(channel, @"hello world");
                
                [(id<CedarDouble>)server reset_sent_messages];
                subject.input.text = @"/notice ik hello world";
                [subject textViewShouldReturn:subject.input];
                server should have_received(@selector(notice:contents:)).with(@"ik", @"hello world");
            });
        });
    });
    
    RBIRCMessage *(^createMessage)() = ^RBIRCMessage*(){
        RBIRCMessage *msg = [[RBIRCMessage alloc] init];
        msg.message = @"Hello world";
        msg.from = @"testuser";
        msg.targets = [@[channel] mutableCopy];
        msg.command = IRCMessageTypePrivmsg;
        msg.timestamp = [NSDate date];
        
        return msg;
    };
    
    describe(@"RBServerVCDelegate responses", ^{
        it(@"should change channels", ^{
            RBIRCServer *server = nice_fake_for([RBIRCServer class]);
            server stub_method("connected").and_return(YES);
            RBIRCChannel *ircChannel = nice_fake_for([RBIRCChannel class]);
            server stub_method("serverName").and_return(@"Test Server");
            ircChannel stub_method("name").and_return(@"#testuser");
            NSNotification *note = [[NSNotification alloc] initWithName:RBServerViewDidChangeChannel object:@{@"server": server, @"channel": ircChannel} userInfo:nil];
            [subject serverViewChangedChannel:note];
            subject.channel should equal(ircChannel.name);
        });
    });
    
    describe(@"disconnects", ^{
        beforeEach(^{
            subject.server stub_method("connected").and_return(NO);
            [subject IRCServerConnectionDidDisconnect:subject.server];
        });
        
        it(@"should display disconnected", ^{
            subject.navigationItem.title should equal(@"Disconnected");
        });
        
        it(@"should still display disconnected on channel change", ^{
            RBIRCChannel *ircChannel = nice_fake_for([RBIRCChannel class]);
            ircChannel stub_method("name").and_return(@"#testchannel");
            NSNotification *note = [[NSNotification alloc] initWithName:RBServerViewDidChangeChannel object:@{@"channel": ircChannel} userInfo:nil];
            [subject serverViewChangedChannel:note];
            subject.channel should be_nil;
            subject.navigationItem.title should equal(@"Disconnected");
        });
        
        it(@"should disable text input", ^{
            subject.input.editable should be_falsy;
            subject.inputCommands.enabled should be_falsy;
        });
    });
    
    describe(@"displaying messages", ^{
        __block RBIRCChannel *ircChannel;
        __block NSMutableArray *log;
        beforeEach(^{
            RBIRCServer *server = fake_for([RBIRCServer class]);
            ircChannel = nice_fake_for([RBIRCChannel class]);
            RBIRCMessage *msg = createMessage();
            log = [[NSMutableArray alloc] init];
            [log addObject:msg];
            
            ircChannel stub_method("name").and_return(channel);
            ircChannel stub_method("log").and_return(log);
            
            server stub_method("channels").and_return(@{channel: ircChannel});
            server stub_method("objectForKeyedSubscript:").and_return(ircChannel);
            
            spy_on(subject.tableView);
            
            subject.server = server;
            subject.channel = channel;
            [subject.tableView reloadData];
        });
        
        it(@"should display existing messages", ^{
            [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(log.count);
            UITableViewCell *cell = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            UITextView *tv = nil;
            for (UIView *v in cell.contentView.subviews) {
                if ([v isKindOfClass:[UITextView class]]) {
                    tv = (UITextView *)v;
                    break;
                }
            }
            tv should_not be_nil;
            tv.attributedText.string should equal(@"testuser: Hello world");
        });
        
        it(@"should respond to incoming messages when viewing the bottom", ^{
            NSInteger i = log.count;
            RBIRCMessage *msg = createMessage();
            [log addObject:msg];
            [subject IRCServer:subject.server handleMessage:msg];
            [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(i + 1);
            log.count should equal(i+1);
            subject.tableView should_not have_received(@selector(scrollToBottom));
            // sufficiently near the bottom...
        });
        
        it(@"should respond to incoming messages when not viewing the top", ^{
            for (int i = 0; i < 50; i++) {
                [log addObject:createMessage()];
            }
            [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(51);
            [subject.tableView reloadData];
            [subject.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            [(id<CedarDouble>)subject.tableView reset_sent_messages];
            
            RBIRCMessage *msg = createMessage();
            [log addObject:msg];
            
            [subject IRCServer:subject.server handleMessage:msg];
            subject.tableView should_not have_received(@selector(scrollToRowAtIndexPath:atScrollPosition:animated:)).with([NSIndexPath indexPathForRow:log.count - 1 inSection:0], UITableViewScrollPositionBottom, YES);
        });
        
        it(@"should display new messages as they're arrived", ^{
            NSInteger rows = [subject.tableView numberOfRowsInSection:0];
            subject.channel = @"#foo";
            RBIRCMessage *msg = createMessage();
            [log addObject:msg];
            [subject IRCServer:subject.server handleMessage:msg];
            [subject.tableView numberOfRowsInSection:0] should equal(rows+1);
        });
        
        it(@"should memoize message views", ^{
            UITableViewCell *cell1 = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            UITableViewCell *cell2 = [subject tableView:subject.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell1 == cell2 should_not be_truthy; // does a comparison of the memory address, not checks if the objects have the same contents.
        });
    });
});

SPEC_END
