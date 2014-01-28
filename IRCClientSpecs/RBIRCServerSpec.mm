#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "NSData+string.h"
#include <string.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCServerSpec)

describe(@"RBIRCServer", ^{
    __block RBIRCServer *subject;
    __block id<RBIRCServerDelegate> delegate;
    __block NSString *msg;
    
    NSString *channel = @"#foo";

    beforeEach(^{
        subject = [[RBIRCServer alloc] init];
        subject.serverName = @"Test server";
        NSOutputStream *os = nice_fake_for([NSOutputStream class]);
        subject.writeStream = os;
        delegate = nice_fake_for(@protocol(RBIRCServerDelegate));
        [subject addDelegate:delegate];
        spy_on(subject);
        spy_on(os);
        
        os stub_method("write:maxLength:").with(Arguments::anything, Arguments::anything).and_do(^(NSInvocation *invocation){
            NSInteger i;
            [invocation getArgument:&i atIndex:3];
            [invocation setReturnValue:&i];
        });
        os stub_method("open");
        
        
        NSInputStream *is = nice_fake_for([NSInputStream class]);
        is stub_method("hasBytesAvailable").and_return(YES);
        is stub_method("read:maxLength:").with(Arguments::anything, Arguments::anything).and_do(^(NSInvocation *invocation) {
            uint8_t buffer[513];
            [invocation getArgument:(void *)buffer atIndex:2];
            strncpy((char *)buffer, (const char *)[msg UTF8String], 512);
            NSInteger i = 0;//[msg length];
            [invocation setReturnValue:&i];
        });
        is stub_method("open");
        is stub_method("setDelegate:").with(Arguments::anything);
        
        subject.readStream = is;
        
        msg = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you\r\n"];
    });
    
    it(@"should have at least 1 delegate", ^{
        subject.delegates.count should be_gte(1);
    });
    
    it(@"should handle stream events", ^{
        [subject stream:subject.readStream handleEvent:NSStreamEventHasBytesAvailable];
        //subject should have_received("receivedString:").with(msg);
    });
    
    it(@"should handle messages", ^{
        [subject receivedString:msg];
        delegate should have_received("IRCServer:handleMessage:").with(subject).and_with(Arguments::any([RBIRCMessage class]));
        subject.channels.count should be_gte(0);
    });
    
    it(@"should connect", ^{
        subject.nick = @"testname";
        [subject connect:@"testname" withPassword:nil];
        subject.writeStream should have_received("open");
        subject.readStream should have_received("open");
        subject.readStream should have_received("setDelegate:").with(subject);
        subject should have_received("nick:").with(@"testname");
        subject should have_received("sendCommand:").with(@"nick testname");
        subject should have_received("sendCommand:").with(@"user testname foo bar testname");
        subject.connected should be_truthy;
    });
    
    describe(@"sending server commands", ^{
        it(@"should send raw commands", ^{
            [subject sendCommand:[msg substringToIndex:msg.length - 2]];
            subject.writeStream should have_received("write:maxLength:").with([msg UTF8String]).and_with([msg length]);
            delegate should_not have_received("IRCServerConnectionDidDisconnect");
        });
        
        it(@"should change nick", ^{
            [subject nick:@"hello"];
            subject should have_received("sendCommand:").with(@"nick hello");
            subject.nick should equal(@"hello");
        });
        
        it(@"should oper", ^{
            [subject oper:@"foo" password:@"bar"];
            subject should have_received("sendCommand:").with(@"oper foo bar");
        });
        
        it(@"should quit", ^{
            [subject quit:@"foo"];
            subject should have_received("sendCommand:").with(@"quit foo");
        });
        
        it(@"should join without password", ^{
            [subject join:channel];
            subject should have_received("sendCommand:").with(@"join #foo");
        });
        
        it(@"should join with password", ^{
            [subject join:channel Password:@"bar"];
            subject should have_received("sendCommand:").with(@"join #foo bar");
        });
        
        void (^checkNotSent)(void) = ^{
            delegate should have_received("IRCServer:invalidCommand:").with(subject, Arguments::any([NSError class]));
            subject should_not have_received("sendCommand:").with(Arguments::anything);
        };
        
        it(@"should not allow you to part from an unjoined channel", ^{
            [subject part:channel];
            checkNotSent();
        });
        
        it(@"should not allow you to topic an unjoined channel", ^{
            [subject topic:channel topic:@"hello"];
            checkNotSent();
        });
        
        it(@"should not allow you to kick in an unjoined channel", ^{
            [subject kick:channel target:@"hello"];
            checkNotSent();
        });
    });
    
    describe(@"sending channel commands", ^{
        beforeEach(^{
            [subject join:channel];
        });
        
        void (^checkSend)(NSString *) = ^(NSString *str){
            delegate should_not have_received("IRCServer:invalidCommand:").with(subject, Arguments::any([NSError class]));
            subject should have_received("sendCommand:").with(str);
        };
        
        it(@"should part", ^{
            [subject part:channel message:@"you are the weakest link"];
            checkSend(@"part #foo :you are the weakest link");
        });
        
        it(@"should mode", ^{
            [subject mode:channel options:@[@"+b", @"ik"]];
            checkSend(@"mode #foo +b ik");
        });
        
        it(@"should kick", ^{
            [subject kick:channel target:@"ik" reason:@"no reason"];
            checkSend(@"kick #foo ik :no reason");
        });
        
        it(@"should topic", ^{
            [subject topic:channel topic:@"new topic"];
            checkSend(@"topic #foo :new topic");
        });
        
        it(@"should private message", ^{
            [subject privmsg:@"target" contents:@"hello world"];
            checkSend(@"privmsg target :hello world");
        });
        
        it(@"should notice", ^{
            [subject notice:@"target" contents:@"hello world"];
            checkSend(@"notice target :hello world");
        });
    });
});

SPEC_END
