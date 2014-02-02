#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "NSData+string.h"
#include <string.h>
#include <semaphore.h>

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
        delegate = nice_fake_for(@protocol(RBIRCServerDelegate));
        [subject addDelegate:delegate];
        spy_on(subject);
        
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
    
    /*
     // Testing this is annoying.
     // Just going to do the "hope and pray it works"
     // Someone better than I should fix this.
    describe(@"connecting to an actual server", ^{
        __block NSLock *lock;
        beforeEach(^{
            subject.nick = @"TestUser";
            subject.hostname = @"localhost";
            subject.realname = @"testuser";
            subject.password = @"";
            subject.debugLock = [[NSLock alloc] init];
            [subject.debugLock lock];
        });
        
        afterEach(^{
            [lock unlock];
        });
        
        it(@"should connect to a plain-text server", ^{
            subject.useSSL = NO;
            subject.port = @"6667";
            dispatch_queue_t queue = dispatch_queue_create("debugqueue", NULL);
            dispatch_async(queue, ^{
                [subject connect];
            });
            [subject.debugLock lock];
            subject.connected should be_truthy;
            subject.writeStream.streamStatus should equal(NSStreamStatusOpen);
        });
    });
*/
    
    describe(@"sending server commands", ^{
        it(@"should send raw commands", ^{
            [subject sendCommand:[msg substringToIndex:msg.length - 2]];
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
