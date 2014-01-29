#import "RBChannelViewController.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "RBIRCChannel.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBChannelViewControllerSpec)

describe(@"RBChannelViewController", ^{
    __block RBChannelViewController *subject;
    __block RBIRCServer *server;
    
    NSString *channel = @"#foo";

    beforeEach(^{
        subject = [[RBChannelViewController alloc] init];
        [subject view];
        
        subject.channel = channel;

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
        spy_on(server);
        subject.server = server;
    });
    
    describe(@"text input", ^{
        it(@"should nick", ^{
            subject.input.text = @"/nick";
            [subject textFieldShouldReturn:subject.input];
            server should_not have_received("nick:");
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/nick foobar";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("nick:").with(@"foobar");
        });
        
        it(@"should oper", ^{
            subject.input.text = @"/oper foo";
            [subject textFieldShouldReturn:subject.input];
            server should_not have_received("oper:password:");
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/oper foo bar";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("oper:password:").with(@"foo", @"bar");
        });
        
        it(@"should quit", ^{
            subject.input.text = @"/quit";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("quit:").with(subject.server.nick);
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/quit foobar";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("quit:").with(@"foobar");
        });
        
        it(@"should mode", ^{
            subject.input.text = @"/mode +b ik";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("mode:options:").with(channel, @[@"+b", @"ik"]);
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/mode +b ik";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("mode:options:").with(channel, @[@"+b", @"ik"]);
        });
        
        it(@"should kick", ^{
            subject.input.text = @"/kick ik";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("kick:target:reason:").with(channel, @"ik", subject.server.nick);
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/kick ik reason";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("kick:target:reason:").with(channel, @"ik", @"reason");
            
            [(id<CedarDouble>)server reset_sent_messages];
            subject.input.text = @"/kick";
            [subject textFieldShouldReturn:subject.input];
            server should_not have_received("kick:target:");
            server should_not have_received("kick:target:reason:");
        });
        
        it(@"should privmsg", ^{
            subject.input.text = @"hello world";
            [subject textFieldShouldReturn:subject.input];
            server should have_received("privmsg:contents:").with(channel, @"hello world");
        });
    });
    
    RBIRCMessage *(^createMessage)() = ^RBIRCMessage*(){
        RBIRCMessage *msg = fake_for([RBIRCMessage class]);
        msg stub_method("message").and_return(@"Hello world");
        msg stub_method("from").and_return(@"testuser");
        msg stub_method("to").and_return(channel);
        msg stub_method("command").and_return(IRCMessageTypePrivmsg);
        msg stub_method("timestamp").and_return([NSDate date]);
        
        return msg;
    };
    
    describe(@"RBServerVCDelegate responses", ^{
        it(@"should change channels", ^{
            RBIRCServer *server = nice_fake_for([RBIRCServer class]);
            RBIRCChannel *ircChannel = nice_fake_for([RBIRCChannel class]);
            server stub_method("serverName").and_return(@"Test Server");
            ircChannel stub_method("name").and_return(@"#hello");
            [subject server:server didChangeChannel:ircChannel];
            subject.channel should equal(ircChannel.name);
            subject.navigationItem.title should equal(ircChannel.name);
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
            cell.textLabel.text should equal(@"testuser: Hello world");
        });
        
        it(@"should respond to incoming messages when viewing the bottom", ^{
            NSInteger i = log.count;
            [log addObject:createMessage()];
            [subject IRCServer:subject.server handleMessage:createMessage()];
            [subject tableView:subject.tableView numberOfRowsInSection:0] should equal(i + 1);
            log.count should equal(i+1);
            subject.tableView should have_received(@selector(scrollToRowAtIndexPath:atScrollPosition:animated:)).with([NSIndexPath indexPathForRow:i inSection:0], UITableViewScrollPositionBottom, YES);
        });
        
        it(@"should respond to incoming messages when not viewing the top", ^{
            for (int i = 0; i < 50; i++) {
                [log addObject:createMessage()];
            }
            [subject tableView:subject.tableView numberOfRowsInSection:0] should be_gte(50);
            [subject.tableView reloadData];
            [subject.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            [(id<CedarDouble>)subject.tableView reset_sent_messages];
            
            [subject IRCServer:subject.server handleMessage:createMessage()];
            subject.tableView should_not have_received(@selector(scrollToRowAtIndexPath:atScrollPosition:animated:)).with([NSIndexPath indexPathForRow:log.count - 1 inSection:0], UITableViewScrollPositionBottom, YES);
        });
    });
});

SPEC_END
