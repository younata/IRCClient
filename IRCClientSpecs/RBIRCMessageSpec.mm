#import "RBIRCMessage.h"
#import "NSString+isNilOrEmpty.h"
#import "NSAttributedString+containsAttributions.h"
#import "UIColor+colorWithHexString.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RBIRCMessageSpec)

describe(@"RBIRCMessage", ^{
    __block RBIRCMessage *msg;
    
    RBIRCMessage *(^createMsg)(NSString *) = ^RBIRCMessage *(NSString *str){
        str = [NSString stringWithFormat:@"%@\r\n", str];
        RBIRCMessage *ret = [[RBIRCMessage alloc] initWithRawMessage:str];
        return ret;
    };

    it(@"should interpret joins properly", ^{
        msg = createMsg(@":foobar!foo@hide-ECFE1E4F.dsl.mindspring.com JOIN #boats");
        msg.message.hasContent should be_falsy;
        msg.from should equal(@"foobar");
        msg.targets[0] should equal(@"#boats");
        msg.command should equal(IRCMessageTypeJoin);
    });
    
    it(@"should interpret private messages properly", ^{
        msg = createMsg(@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :how are you");
        msg.message should equal(@"ik: how are you");
        msg.from should equal(@"ik");
        msg.targets[0] should equal(@"#boats");
        msg.command should equal(IRCMessageTypePrivmsg);
    });
    
    it(@"should interpret notices properly", ^{
        msg = createMsg(@":You!Rachel@hide-DEA18147.com NOTICE foobar :test");
        msg.message should equal(@"You: test");
        msg.from should equal(@"You");
        msg.targets[0] should equal(@"foobar");
        msg.command should equal(IRCMessageTypeNotice);
    });
    
    it(@"should interpret parts properly", ^{
        msg = createMsg(@":You!Rachel@hide-DEA18147.com PART #foo :test");
        msg.message should equal(@"test");
        msg.from should equal(@"You");
        msg.targets[0] should equal(@"#foo");
        msg.command should equal(IRCMessageTypePart);
    });
    
    it(@"should interpret modes properly", ^{
        msg = createMsg(@":You!Rachel@hide-DEA18147.com MODE #foo +b foobar!*@*");
        msg.message should equal(@"MODE +b foobar!*@*");
        msg.extra should be_instance_of([NSArray class]).or_any_subclass();
        msg.extra[0] should equal(@[@"+b"]);
        msg.extra[1] should equal(@"foobar!*@*");
        msg.from should equal(@"You");
        msg.targets[0] should equal(@"#foo");
        msg.command should equal(IRCMessageTypeMode);
        
        msg = createMsg(@":YouiOS MODE YouiOS :+iwxz");
        msg.message should equal(@"MODE YouiOS +iwxz");
        msg.extra should be_instance_of([NSArray class]).or_any_subclass();
        msg.extra[0] should equal(@[@"+iwxz"]);
        msg.targets[0] should equal(@"YouiOS");
        msg.from should equal(@"YouiOS");
        msg.command should equal(IRCMessageTypeMode);
    });
    
    it(@"should interpret kicks properly", ^{
        msg = createMsg(@":You!Rachel@hide-DEA18147.com KICK #foo foobar :You");
        msg.message should equal(@"foobar :You");
        msg.extra should be_instance_of([NSDictionary class]).or_any_subclass();
        msg.from should equal(@"You");
        msg.targets[0] should equal(@"#foo");
        msg.command should equal(IRCMessageTypeKick);
    });
    
    it(@"should interpret pings properly", ^{
        msg = createMsg(@"PING :EF0896");
        msg.message should equal(@"EF0896");
    });
    
    describe(@"Client to Client Protocol (CTCP)", ^{
        NSString *delim = [NSString stringWithFormat:@"%c", 1];
        // DIIIICK.
        describe(@"Extended data", ^{
            it(@"should ACTION", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :%@ACTION dies.%@", delim, delim];
                msg = createMsg(str);
                msg.attributedMessage.string should equal(@"* ik dies.");
            });
            it(@"should DCC", PENDING); // No one I know actually uses this.
            it(@"should SED", PENDING); // I can't actually find a spec for this.
            // Also, NO ONE USES THIS.
        });
        describe(@"request/repl pairs", ^{
            it(@"should FINGER", ^{ // gigidy
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@FINGER%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPFinger);
            });
            
            it(@"should VERSION", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@VERSION%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPVersion);
            });
            
            it(@"should SOURCE", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@SOURCE%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPSource);
            });
            
            it(@"should USERINFO", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@USERINFO%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPUserInfo);
            });
            
            it(@"should CLIENTINFO", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@CLIENTINFO%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPClientInfo);
            });
            
            it(@"should PING", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@PING 123456789%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPPing);
            });
            
            it(@"should TIME", ^{
                NSString *str = [NSString stringWithFormat:@":ik!iank@hide-1664EBC6.iank.org PRIVMSG test :%@TIME%@", delim, delim];
                msg = createMsg(str);
                msg.command should equal(IRCMessageTypeCTCPTime);
            });
        });
    });
    
    describe(@"Text Stylizations", ^{
        RBIRCMessage *(^stylizedMsg)(NSString *) = ^RBIRCMessage *(NSString *msg) {
            msg = [@":ik!iank@hide-1664EBC6.iank.org PRIVMSG #boats :" stringByAppendingString:msg];
            return createMsg(msg);
        };
        
        NSString *(^charToString)(char) = ^NSString *(char c) {
            return [NSString stringWithFormat:@"%c", c];
        };
        
        describe(@"colors", ^{
            NSString *redStr = @"FF0000";
            NSString *orangeStr = @"FF8000";
            it(@"should have a working colorFromHexString", ^{
                UIColor *color = [UIColor colorWithHexString:redStr];
                CGFloat r,g,b,a;
                [color getRed:&r green:&g blue:&b alpha:&a];
                r should equal(1.0);
                g should equal(0.0);
                b should equal(0.0);
                a should equal(1.0);
            });
            
            UIColor *red = [UIColor colorWithHexString:redStr];
            UIColor *orange = [UIColor colorWithHexString:orangeStr];
            
            NSString *colorDelim = charToString(3);
            it(@"should work for single color in entire message", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello World%@", colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red] should be_truthy;
            });
            
            it(@"should work for a single color in entire message with background", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello World%@", colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange] should be_truthy;
            });
            
            it(@"should work for a single color in part of the message", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello%@ World", colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(2, 5)] should be_truthy;
                
                msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello%@ World", colorDelim, colorDelim]);
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(2, 5)] should be_truthy;
            });
            
            it(@"should work for switching colors", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello %@3 World%@", colorDelim, colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(2, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:orange range:NSMakeRange(10, 6)] should be_truthy;
                
                msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello %@3,2 World%@", colorDelim, colorDelim, colorDelim]);
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(2, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:red range:NSMakeRange(10, 6)] should be_truthy;
            });
            
            it(@"should switch foreground, but not background colors.", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello %@3 World%@", colorDelim, colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(2, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(2, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:orange range:NSMakeRange(10, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(10, 6)] should be_truthy;
            });
        });
        
        describe(@"bold", ^{
            NSString *boldDelim = charToString(2);
            it(@"should bold entire line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Hello world%@", boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3)] should be_truthy;
            });
            
            it(@"should bold part of a line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Hello%@ world", boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(1, 5)] should be_truthy;
            });
            
            it(@"should bold two separate parts of the line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Rachel%@ says %@hi%@", boldDelim, boldDelim, boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(1, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(16, 2)] should be_truthy;
                
            });
        });
        
        describe(@"italic", ^{
            
        });
        
        describe(@"strikethrough", ^{
            
        });
        
        describe(@"underline", ^{
            
        });
        
        describe(@"double underline", ^{
            
        });
    });
});

SPEC_END
