#import "RBIRCServer.h"
#import "RBIRCMessage.h"
#import "RBIRCChannel.h"
#import "NSData+string.h"
#include <string.h>
#include <semaphore.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCServerSpec)

describe(@"RBIRCServer", ^{
    __block RBIRCServer *subject;
    __block NSString *msg;
    
    NSString *channel = @"#foo";

    beforeEach(^{
        subject = [[RBIRCServer alloc] init];
        subject.serverName = @"Test server";
        /* testing the tests
        delegate stub_method(@selector(IRCServer:handleMessage:)).and_do(^(NSInvocation *inv){
            id arg1;
            id arg2;
            [inv getArgument:&arg1 atIndex:2];
            [inv getArgument:&arg2 atIndex:3];
            NSLog(@"received IRCServer:handleMessage: with args '%@', '%@'", arg1, arg2);
        });
        delegate stub_method(@selector(IRCServer:invalidCommand:)).and_do(^(NSInvocation *inv){
            id arg1;
            id arg2;
            [inv getArgument:&arg1 atIndex:2];
            [inv getArgument:&arg2 atIndex:3];
            NSLog(@"received IRCServer:invalidCommand: with args '%@', '%@'", arg1, arg2);
        });
        // */
        spy_on(subject);
        
        msg = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you\r\n"];
    });
    
    it(@"should default to reconnect on startup", ^{
        subject.connectOnStartup should be_truthy;
    });
    
    it(@"should handle loading from NSUserDefaults correctly", ^{
        RBIRCServer *server = [[RBIRCServer alloc] initWithHostname:@"testServer" ssl:YES port:@"6697" nick:@"testnick" realname:@"testnick" password:@""];
        server.nick = @"testnick";
        server.serverName = @"server";
        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:server];
        RBIRCServer *s = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        [s isEqual:server] should be_truthy;
        s.connectOnStartup should equal(server.connectOnStartup);
    });
    
    it(@"should handle stream events", ^{
        [subject stream:subject.readStream handleEvent:NSStreamEventHasBytesAvailable];
        //subject should have_received("receivedString:").with(msg);
    });
    
    it(@"should handle messages", ^{
        [subject receivedString:msg];
        subject.channels.count should be_gte(0);
    });
    
    it(@"should notify listeners of disconnect", ^{
        [subject stream:nil handleEvent:NSStreamEventEndEncountered];
        // nsnotification stuff...
    });
    
    describe(@"sending server commands", ^{
        it(@"should send raw commands", ^{
            [subject sendCommand:[msg substringToIndex:msg.length - 2]];
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
            subject should_not have_received(@selector(sendCommand:)).with(Arguments::anything);
        };
        
        it(@"should not allow you to part from an unjoined channel", ^{
            @try {
                [subject part:channel];
            }
            @catch (NSException *error) {
                
            }
            checkNotSent();
        });
        
        it(@"should not allow you to topic an unjoined channel", ^{
            @try {
                [subject topic:channel topic:@"hello"];
            }
            @catch (NSException *error) {
            }
            checkNotSent();
        });
        
        it(@"should not allow you to kick in an unjoined channel", ^{
            @try {
                [subject kick:channel target:@"hello"];
            }
            @catch (NSException *error) {
            }
            checkNotSent();
        });
    });
    
    describe(@"sending channel commands", ^{
        beforeEach(^{
            [subject join:channel];
        });
        
        void (^checkSend)(NSString *) = ^(NSString *str){
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
    
    describe(@"sending CTCP responses", ^{
        NSString *delim = [NSString stringWithFormat:@"%c", 1];
        
        __block NSString *str;
        
        NSString *(^createCTCPMessage)(NSString *) = ^NSString *(NSString *command){
            return [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@%@%@\r\n", delim, command, delim];
        };
        NSString *(^createCTCPResponse)(NSString *) = ^NSString *(NSString *response){
            return [NSString stringWithFormat:@"NOTICE ik :%@%@%@\r\n", delim, response, delim];
        };
        beforeEach(^{
            subject.nick = @"test";
            spy_on(subject);
        });
        
        it(@"should FINGER", ^{
            str = createCTCPMessage(@"FINGER");
            [subject receivedString:str];
            subject should have_received("sendCommand:").with(createCTCPResponse(@"FINGER :Unknown"));
        });
        
        it(@"should VERSION", ^{
            str = createCTCPMessage(@"VERSION");
            [subject receivedString:str];
            subject should have_received("sendCommand:").with(Arguments::any([NSString class]));
        });
        
        it(@"should SOURCE", ^{
            [subject receivedString:createCTCPMessage(@"SOURCE")];
            subject should have_received("sendCommand:").with(createCTCPResponse(@"SOURCE https://github.com/younata/IRCClient/"));
        });
        
        it(@"should USERINFO", ^{
            [subject receivedString:createCTCPMessage(@"USERINFO")];
            subject should have_received("sendCommand:").with(createCTCPResponse(@"USERINFO :Unknown"));
        });
        
        it(@"should CLIENTINFO", ^{
            [subject receivedString:createCTCPMessage(@"CLIENTINFO")];
            subject should have_received("sendCommand:").with(createCTCPResponse(@"CLIENTINFO FINGER VERSION SOURCE USERINFO CLIENTINFO PING TIME"));
        });
        
        it(@"should PING", ^{
            double firstTimeStamp = [[NSDate date] timeIntervalSince1970];
            NSString *str = [NSString stringWithFormat:@"PING %f", firstTimeStamp];
            [subject receivedString:createCTCPMessage(str)];
            subject should have_received("sendCommand:").with(createCTCPResponse(str));
            RBIRCMessage *msg = [[subject[@"ik"] log] lastObject];
            [msg.attributedMessage.string hasPrefix:@"CTCP Ping reply: "] should be_truthy;
            [msg.attributedMessage.string hasSuffix:@"seconds"] should be_truthy;
            NSInteger loc =[@"CTCP Ping reply: " length];
            NSRange range = NSMakeRange(loc, [msg.attributedMessage.string rangeOfString:@" seconds"].location - loc);
            str = [msg.attributedMessage.string substringWithRange:range];
            double d = [str doubleValue];
            d should_not equal(0);
            double secondTimeStamp = [[NSDate date] timeIntervalSince1970];
            d should be_lte(secondTimeStamp - firstTimeStamp);
        });
        
        it(@"should TIME", ^{
            [subject receivedString:createCTCPMessage(@"TIME")];
            subject should have_received("sendCommand:");
        });
    });
});

SPEC_END
