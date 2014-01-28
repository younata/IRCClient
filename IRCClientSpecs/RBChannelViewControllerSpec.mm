#import "RBChannelViewController.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

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
});

SPEC_END
