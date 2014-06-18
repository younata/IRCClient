#import "RBIRCMessage.h"
#import "NSString+isNilOrEmpty.h"
#import "NSAttributedString+containsAttributions.h"
#import "UIColor+colorWithHexString.h"
#import "NSAttributedString+attributes.h"

#import "RBConfigurationKeys.h"

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
        
        describe(@"nick colors", ^{
            it(@"should color nicks the first a message is sent...", ^{
            });
            
            it(@"should persist colors throughout multiple calls.", ^{
                
            });
        });
        
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
                msg.attributedMessage.string should equal(@"ik: Hello World");
            });
            
            it(@"should work for a single color in entire message with background", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello World%@", colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
            });
            
            it(@"should work for a single color in part of the message", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello%@ World", colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(4, 5)] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
                
                msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello%@ World", colorDelim, colorDelim]);
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(4, 5)] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
            });
            
            it(@"should work for switching colors", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello %@3World%@", colorDelim, colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(4, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:orange range:NSMakeRange(10, 5)] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
                
                msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello %@3,2World%@", colorDelim, colorDelim, colorDelim]);
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(4, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:red range:NSMakeRange(10, 5)] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
            });
            
            it(@"should switch foreground, but not background colors.", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2,3Hello %@3World%@", colorDelim, colorDelim, colorDelim]);
                
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(4, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(4, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSForegroundColorAttributeName value:orange range:NSMakeRange(10, 5)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSBackgroundColorAttributeName value:orange range:NSMakeRange(10, 5)] should be_truthy;
                
                msg.attributedMessage.string should equal(@"ik: Hello World");
            });
        });
        
        describe(@"bold", ^{
            NSString *boldDelim = charToString(2);
            it(@"should bold entire line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Hello world%@", boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3)] should be_truthy;
                msg.attributedMessage.string should equal(@"ik: Hello world");
            });
            
            it(@"should bold part of a line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Hello%@ world", boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(4, 5)] should be_truthy;
                msg.attributedMessage.string should equal(@"ik: Hello world");
            });
            
            it(@"should bold two separate parts of the line", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@Rachel%@ says %@hi%@", boldDelim, boldDelim, boldDelim, boldDelim]);
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(4, 6)] should be_truthy;
                [msg.attributedMessage containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(16, 2)] should be_truthy;
                msg.attributedMessage.string should equal(@"ik: Rachel says hi");
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
        
        describe(@"combinations", ^{
            UIColor *red = [UIColor colorWithHexString:@"FF0000"];
            NSString *colorDelim = charToString(3);
            NSString *boldDelim = charToString(2);
            it(@"should have correct attribution and character removal for combinations of two or more stylizations", ^{
                RBIRCMessage *msg = stylizedMsg([NSString stringWithFormat:@"%@2Hello %@ world%@%@", colorDelim, boldDelim, boldDelim, colorDelim]);
                
                NSAttributedString *str = msg.attributedMessage;
                
                str.string should equal(@"ik: Hello  world");
                [str containsAttribution:NSForegroundColorAttributeName value:red range:NSMakeRange(4, 12)] should be_truthy;
                [str containsAttribution:NSStrokeWidthAttributeName value:@(-3) range:NSMakeRange(10, 6)] should be_truthy;
            });
        });
        
        /*
         Bleh, asynch...
        describe(@"images", ^{
            beforeEach(^{
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RBConfigLoadImages];
            });
            
            afterEach(^{
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RBConfigLoadImages];
            });
            
            fdescribe(@"SFW images", ^{
                it(@"should append a text attachment for messages with links to images", ^{
                    // synchronization errors...
                    RBIRCMessage *msg = stylizedMsg(@"http://i.imgur.com/hjw7z6A.jpg");
                    
                    msg.attributedMessage.string should equal(@"ik: http://i.imgur.com/hjw7z6A.jpg");
                    NSArray *attachments = [msg.attributedMessage rangesForAttribute:NSAttachmentAttributeName];
                    attachments.count should equal(1);
                    
                    NSArray *firstSet = attachments.firstObject;
                    firstSet.firstObject should be_instance_of([NSTextAttachment class]);
                });
            });
            
            describe(@"NSFW images", ^{
                beforeEach(^{
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RBConfigDontLoadNSFW];
                });
                
                afterEach(^{
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RBConfigDontLoadNSFW];
                });
                
                it(@"should not append a text attachment for messages with links to nsfw images", ^{
                    RBIRCMessage *msg = stylizedMsg(@"http://i.imgur.com/NI4MgcK.gif nsfw");
                    
                    msg.attributedMessage.string should equal(@"ik: http://i.imgur.com/NI4MgcK.gif nsfw");
                    [msg.attributedMessage rangesForAttribute:NSAttachmentAttributeName].count should equal(0);
                });
                
                it(@"should append a nsfw image if 'display nsfw images' is checked in configs", ^{
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RBConfigDontLoadNSFW];
                    
                    RBIRCMessage *msg = stylizedMsg(@"http://i.imgur.com/NI4MgcK.gif nsfw");
                    
                    msg.attributedMessage.string should equal(@"ik: http://i.imgur.com/NI4MgcK.gif nsfw");
                    NSArray *attachments = [msg.attributedMessage rangesForAttribute:NSAttachmentAttributeName];
                    attachments.count should equal(1);
                    [attachments[0][0] image] should be_instance_of([UIImage class]);
                });
            });
            
            describe(@"Invalid images", ^{ // that is, links which look like they should be images, but really aren't
                it(@"should not append a text attachment", ^{
                    RBIRCMessage *msg = stylizedMsg(@"http://younata.com/image.jpg");
                    
                    msg.attributedMessage.string should equal(@"ik: http://younata.com/image.jpg");
                    [msg.attributedMessage rangesForAttribute:NSAttachmentAttributeName].count should equal(0);
                });
            });
        });
        */
    });
});

SPEC_END
