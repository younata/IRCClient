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
    IRCMessageTypePing,
    IRCMessageTypePart,
    IRCMessageTypePrivmsg,
    IRCMessageTypeNotice,
    IRCMessageTypeMode,
    IRCMessageTypeKick,
    IRCMessageTypeTopic,
    IRCMessageTypeNick,
    IRCMessageTypeOper,
    IRCMessageTypeQuit,
    IRCMessageTypeUnknown
} IRCMessageType;

@interface RBIRCMessage : NSObject

@property (nonatomic, strong) NSDate *timestamp; // arrival time
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *rawMessage;
@property (nonatomic, strong) NSString *from;
@property (nonatomic, strong) NSString *to;
@property (nonatomic) IRCMessageType command;
@property (nonatomic, strong) id extra;

+(NSString *)getMessageStringForType:(IRCMessageType)messagetype;
+(IRCMessageType)getMessageTypeForString:(NSString *)messageString;
-(instancetype)initWithRawMessage:(NSString *)raw;

@end
