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

@property (nonatomic, readonly, strong) NSDate *timestamp; // arrival time
@property (nonatomic, readonly, strong) NSString *message;
@property (nonatomic, readonly, strong) NSString *rawMessage;
@property (nonatomic, readonly, strong) NSString *from;
@property (nonatomic, readonly, strong) NSString *to;
@property (nonatomic, readonly) IRCMessageType command;
@property (nonatomic, readonly, strong) id extra;

+(NSString *)getMessageStringForType:(IRCMessageType)messagetype;
+(IRCMessageType)getMessageTypeForString:(NSString *)messageString;
-(instancetype)initWithRawMessage:(NSString *)raw;

@end
