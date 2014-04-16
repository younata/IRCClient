//
//  RBIRCChannel.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBIRCChannel.h"
#import "RBIRCServer.h"
#import "RBIRCMessage.h"

#import "IRCNumericReplies.h"

#import "RBScriptingService.h"

@interface RBIRCChannel ()

@property (nonatomic, strong) NSMutableArray *unreadMessages;

@end

@implementation RBIRCChannel

-(instancetype)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        _log = [[NSMutableArray alloc] init];
        _names = [[NSMutableArray alloc] init];
        self.askedForNames = YES;
        self.connectOnStartup = YES;
        self.unreadMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]) != nil) {
        _name = [decoder decodeObjectForKey:@"name"];
        _log = [[NSMutableArray alloc] init];
        _names = [[NSMutableArray alloc] init];
        
        self.server = nil;
        self.topic = nil;
        self.connectOnStartup = [decoder decodeBoolForKey:@"connectOnStartup"];
        self.unreadMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeBool:self.connectOnStartup forKey:@"connectOnStartup"];
}

-(BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[RBIRCChannel class]] && [[object name] isEqualToString:_name]);
}

-(void)logMessage:(RBIRCMessage *)message
{
    BOOL shouldResortNames = NO;
    if (message.command == IRCMessageTypeTopic) {
        self.topic = message.message;
    } else if (message.command == IRCMessageTypeJoin) {
        if ([message.from isEqualToString:self.server.nick]) {
        } else {
            [self.names addObject:message.from];
            [UITextChecker learnWord:message.from];
            shouldResortNames = YES;
        }
    } else if (message.command == IRCMessageTypePart) {
        if ([message.from isEqualToString:self.server.nick]) {
            // should not have recieved this.
            NSLog(@"Error: Recieved a self part");
        } else {
            [self.names removeObject:message.from];
            [UITextChecker unlearnWord:message.from];
            shouldResortNames = YES;
        }
    } else if (message.command == IRCMessageTypeNames) {
        if (self.askedForNames) {
            for (NSString *word in self.names) {
                [UITextChecker unlearnWord:word];
            }
            [self.names removeAllObjects];
            self.askedForNames = NO;
        }
        [self.names addObjectsFromArray:message.extra];
        for (NSString *word in message.extra) {
            [UITextChecker learnWord:word];
        }
    } else if (message.commandNumber == RPL_ENDOFNAMES) {
        self.askedForNames = YES;
        shouldResortNames = YES;
    } else if (message.command == IRCMessageTypePrivmsg ||
               message.command == IRCMessageTypeNotice || // or CTCP...
               (message.command >= IRCMessageTypeCTCPFinger && message.command != 255)) {
        [(NSMutableArray *)self.unreadMessages addObject:message];
    }
    
    if (shouldResortNames) {
        [self.names sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b){
            // handle ops case...
            // owner = ~
            // sop = &
            // op = @
            // hop = %
            // voice = +
            for (NSString *prefix in @[@"~", @"&", @"@", @"%", @"+"]) {
                BOOL ap = [a hasPrefix:prefix];
                BOOL bp = [b hasPrefix:prefix];
                if (ap || bp) {
                    if (ap && bp) {
                        return [a caseInsensitiveCompare:b];
                    }
                    if (ap) {
                        return NSOrderedAscending;
                    }
                    return NSOrderedDescending;
                }
            }
            return [a caseInsensitiveCompare:b];
        }];
    }
    
    if (!(message.command == IRCMessageTypeNames ||
          message.commandNumber == RPL_ENDOFNAMES ||
          message == nil)) {
        [_log addObject:message];
    }
    
    [[RBScriptingService sharedInstance] channel:self didLogMessage:message];
}

-(BOOL)isChannel
{
    return [self.name hasPrefix:@"#"] || [self.name hasPrefix:@"&"];
}

-(NSArray *)read
{
    NSArray *ret = [NSArray arrayWithArray:self.unreadMessages];
    [(NSMutableArray *)self.unreadMessages removeAllObjects];
    return ret;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: connect: %@", self.name, self.connectOnStartup ? @"YES" : @"NO"];
}

@end
