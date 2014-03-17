#import "RBIRCChannel.h"
#import "RBIRCMessage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCChannelSpec)

describe(@"RBIRCChannel", ^{
    __block RBIRCChannel *subject;
    static NSString *name = @"#test";

    beforeEach(^{
        subject = [[RBIRCChannel alloc] initWithName:name];
    });
    
    it(@"should default to connect on startup", ^{
        subject.connectOnStartup should be_truthy;
    });
    
    it(@"should handle loading from NSUserDefaults correctly", ^{
        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:subject];
        RBIRCChannel *c = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        [c isEqual:subject] should be_truthy;
        c.connectOnStartup should equal(subject.connectOnStartup);
    });
    
    describe(@"unread messages", ^{
        RBIRCMessage *(^newPrivateMessage)() = ^RBIRCMessage *(){
            RBIRCMessage *ret = [[RBIRCMessage alloc] initWithRawMessage:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you"];
            return ret;
        };
        
        RBIRCMessage *(^newNotice)() = ^RBIRCMessage *(){
            RBIRCMessage *ret = [[RBIRCMessage alloc] initWithRawMessage:@":You!Rachel@hide-DEA18147.com NOTICE #boats :test"];
            return ret;
        };
        
        RBIRCMessage *(^newMode)() = ^RBIRCMessage *(){
            RBIRCMessage *ret = [[RBIRCMessage alloc] initWithRawMessage:@":You!Rachel@hide-DEA18147.com MODE #boats +b foobar!*@*"];
            return ret;
        };
        
        it(@"should increment on PRIVMSG", ^{
            NSInteger firstUnread = subject.unreadMessages.count;
            [subject logMessage:newPrivateMessage()];
            NSInteger secondUnread = subject.unreadMessages.count;
            secondUnread should be_greater_than(firstUnread);
        });
        
        it(@"should increment on NOTICE", ^{
            NSInteger firstUnread = subject.unreadMessages.count;
            [subject logMessage:newNotice()];
            NSInteger secondUnread = subject.unreadMessages.count;
            secondUnread should be_greater_than(firstUnread);
        });
        
        it(@"should not increment on others", ^{
            NSInteger firstUnread = subject.unreadMessages.count;
            [subject logMessage:newMode()];
            NSInteger secondUnread = subject.unreadMessages.count;
            secondUnread should equal(firstUnread);
        });
        
        it(@"should be reduced to 0 when read", ^{
            [subject logMessage:newPrivateMessage()];
            [subject read];
            subject.unreadMessages.count should equal(0);
        });
        
        it(@"should return the unread messages on read", ^{
            [subject logMessage:newPrivateMessage()];
            NSArray *unread = [NSArray arrayWithArray:subject.unreadMessages];
            unread.count should be_greater_than(0);
            NSArray *messages = [subject read];
            messages should equal(unread);
        });
    });
});

SPEC_END
