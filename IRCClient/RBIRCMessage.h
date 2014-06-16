//
//  RBIRCMessage.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    IRCMessageTypeJoin = 0,
    IRCMessageTypePing = 1,
    IRCMessageTypePart = 2,
    IRCMessageTypePrivmsg = 3,
    IRCMessageTypeNotice = 4,
    IRCMessageTypeMode = 5,
    IRCMessageTypeKick = 6,
    IRCMessageTypeTopic = 7,
    IRCMessageTypeNick = 8,
    IRCMessageTypeOper = 9,
    IRCMessageTypeQuit = 10,
    IRCMessageTypeNames = 11,
    IRCMessageTypeInvite = 12,
    IRCMessageTypeCTCPFinger = 13,
    IRCMessageTypeCTCPVersion = 14,
    IRCMessageTypeCTCPSource = 15,
    IRCMessageTypeCTCPUserInfo = 16,
    IRCMessageTypeCTCPClientInfo = 17,
    IRCMessageTypeCTCPPing = 18,
    IRCMessageTypeCTCPTime = 19,
    IRCMessageTypeCTCPErrMsg = 20,
    IRCMessageTypeUnknown = 255
} IRCMessageType;

typedef enum {
    styleColor = 0,
    styleBold = 1,
    styleItalic = 2,
    styleStrike = 4,
    styleUnderline = 8,
    styleDoubleUnderline = 16,
} stylizeFlag;

@class RBIRCChannel;
@class RBIRCServer;

@interface RBIRCMessage : NSObject

@property (nonatomic, strong) NSDate *timestamp; // arrival time
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *rawMessage;
@property (nonatomic, strong) NSString *from;
@property (nonatomic, strong) NSMutableArray *targets;
@property (nonatomic) IRCMessageType command;
@property (nonatomic) NSInteger commandNumber;
@property (nonatomic, strong) id extra;
@property (nonatomic, strong) NSAttributedString *attributedMessage;
@property (nonatomic, weak) RBIRCServer *server;

+(NSString *)getMessageStringForType:(IRCMessageType)messagetype;
+(IRCMessageType)getMessageTypeForString:(NSString *)messageString;
-(instancetype)initWithRawMessage:(NSString *)raw;
-(instancetype)initWithRawMessage:(NSString *)raw onServer:(RBIRCServer *)server;
-(NSDictionary *)defaultAttributes;

@end
