#import "RBIRCMessage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCMessageSpec)

describe(@"RBIRCMessage", ^{
    __block RBIRCMessage *msg;
    __block NSString *test;

    it(@"should interpret joins properly", ^{
        test = @":foobar!foo@hide-ECFE1E4F.dsl.mindspring.com JOIN :#boats";
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        msg.message should be_nil;
        msg.from should equal(@"foobar");
        msg.to should equal(@"#boats");
        msg.command should equal(IRCMessageTypeJoin));
    });
    
    it(@"should interpret private messages properly", ^{
        test = @":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you";
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        msg.message should equal(@"how are you");
        msg.from should equal(@"ik");
        msg.to should equal(@"#boats");
        msg.command should equal(IRCMessageTypePrivmsg);
    });
    
    it(@"should interpret notices properly", ^{
        test = @":You!Rachel@hide-DEA18147.com NOTICE foobar :test";
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        msg.message should equal(@"test");
        msg.from should equal(@"You");
        msg.to should equal(@"foobar");
        msg.command should equal(IRCMessageTypeNotice);
    });
    
    it(@"should interpret parts properly", ^{
        test = @":You!Rachel@hide-DEA18147.com PART #foo :test";
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        msg.message should equal(@"test");
        msg.from should equal(@"You");
        msg.to should equal(@"#foo");
        msg.command should equal(IRCMessageTypePart);
    });
    
    it(@"should interpret modes properly", ^{
        test = @":You!Rachel@hide-DEA18147.com MODE #foo +b foobar!*@*"; // ban
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        
        msg.message should equal(@"+b foobar!*@*");
        msg.extra should be_instance_of([NSArray class]);
        msg.extra[0] should equal(@"+b");
        msg.extra[1] should equal(@"foobar!*@*");
        msg.from should equal(@"You");
        msg.to should equal(@"#foo");
        msg.command should equal(IRCMessageTypeMode);
    });
    
    it(@"should interpret kicks properly", ^{
        test = @":You!Rachel@hide-DEA18147.com KICK #foo foobar :You";
        msg = [[RBIRCMessage alloc] initWithRawMessage:test];
        msg.message should equal(@"foobar :You");
        msg.extra should be_instance_of([NSDictionary class]);
        msg.extra[@"target"] should equal(@"foobar");
        msg.extra[@"reason"] should equal(@"You");
        msg.from should equal(@"You");
        msg.to should equal(@"#foo");
        msg.command should equal(IRCMessageTypeKick);
    });
});

SPEC_END
