//
//  RBScriptingService.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBScriptingService.h"
#import "RBScript.h"
#import "RBConfigurationKeys.h"

@interface RBScriptingService ()
{
    dispatch_queue_t queue;
}

@end

@implementation RBScriptingService

+(RBScriptingService *)sharedInstance
{
    static RBScriptingService *ret;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        ret = [[RBScriptingService alloc] init];
    });
    return ret;
}

-(instancetype)init
{
    if ((self = [super init])) {
        _scriptsLoaded = NO;
        queue = dispatch_queue_create("scripts", NULL);
        self.runScriptsConcurrently = NO;
    }
    return self;
}

-(void)loadScripts
{
    if (self.scriptsLoaded) {
        return;
    }
    self.scriptSet = [[NSMutableSet alloc] init];
    self.scriptDict = [[NSMutableDictionary alloc] init];
    
    _scriptsLoaded = YES;
}

-(void)registerScript:(Class)script
{
    NSString *desc = [script description];
    if (desc && self.scriptDict[desc] == nil) {
        [self.scriptDict setObject:script forKey:desc];
    }
}

-(void)runEnabledScripts
{
    if (!self.scriptsLoaded) {
        [self loadScripts];
        _scriptsLoaded = YES;
    }
    
    NSArray *keys = [self scripts];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *key in keys) {
        NSNumber *val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!val) { val = @(NO); }
        dict[key] = val;
    }
    for (NSString *key in keys) {
        Class cls = self.scriptDict[key];
        if (dict[key] && [dict[key] boolValue]) {
            id obj = [[cls alloc] init];
            [self.scriptSet addObject:obj];
        } else {
            id toRM = nil;
            for (id obj in self.scriptSet) {
                if ([obj isMemberOfClass:cls]) {
                    toRM = obj;
                    break;
                }
            }
            if (toRM != nil) {
                [self.scriptSet removeObject:toRM];
            }
        }
    }
}

-(NSArray *)scripts;
{
    return self.scriptDict.allKeys;
}

-(void)runScript:(void (^)(void))command
{
    if (self.runScriptsConcurrently) {
        dispatch_async(queue, ^{
            @autoreleasepool {
                command();
            }
        });
    } else {
        command();
    }
}

#pragma mark - IRC Server

-(void)serverDidConnect:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverDidConnect:server];
        }
    }];
}

-(void)serverDidDisconnect:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverDidDisconnect:server];
        }
    }];
}

-(void)serverDidError:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverDidError:server];
        }
    }];
}

-(void)server:(RBIRCServer *)server didReceiveMessage:(RBIRCMessage *)message
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script server:server didReceiveMessage:message];
        }
    }];
}

#pragma mark - IRC Channel

-(void)channel:(RBIRCChannel *)channel didLogMessage:(RBIRCMessage *)message
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script channel:channel didLogMessage:message];
        }
    }];
}

#pragma mark - Server List View

-(void)serverListWasLoaded:(RBServerViewController *)serverList
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverListWasLoaded:serverList];
        }
    }];
}

-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverList:serverList didCreateNewServerCell:cell];
        }
    }];
}

-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverList:serverList didCreateServerCell:cell forServer:server];
        }
    }];
}

-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverList:serverList didCreateChannelCell:cell forChannel:channel];
        }
    }];
}

-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverList:serverList didCreatePrivateCell:cell forPrivateConversation:conversation];
        }
    }];
}

-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverList:serverList didCreateNewChannelCell:cell];
        }
    }];
}

#pragma mark - Server Editor
-(void)serverEditorWasLoaded:(RBServerEditorViewController *)serverEditor
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverEditorWasLoaded:serverEditor];
        }
    }];
}

-(void)serverEditor:(RBServerEditorViewController *)serverEditor didMakeChangesToServer:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverEditor:serverEditor didMakeChangesToServer:server];
        }
    }];
}

-(void)serverEditorWillBeDismissed:(RBServerEditorViewController *)serverEditor
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script serverEditorWillBeDismissed:serverEditor];
        }
    }];
}

#pragma mark - Channel View
-(void)channelViewWasLoaded:(RBChannelViewController *)channelView
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script channelViewWasLoaded:channelView];
        }
    }];
}

-(void)channelView:(RBChannelViewController *)channelView didDisconnectFromChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script channelView:channelView didDisconnectFromChannel:channel andServer:server];
        }
    }];
}

-(void)channelView:(RBChannelViewController *)channelView didSelectChannel:(RBIRCChannel *)channel andServer:(RBIRCServer *)server
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script channelView:channelView didSelectChannel:channel andServer:server];
        }
    }];
}

-(void)channelView:(RBChannelViewController *)channelView willDisplayMessage:(RBIRCMessage *)message inView:(UITextView *)view
{
    [self runScript:^{
        for (RBScript *script in self.scriptSet) {
            [script channelView:channelView willDisplayMessage:message inView:view];
        }
    }];
}


@end
