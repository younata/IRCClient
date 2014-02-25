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

#import "Nu.h"

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
        [self loadNu];
    }
    return self;
}

-(void)loadNu
{
    NuInit();
    [[Nu sharedParser] parseEval:@"(load \"nu\")"];
}

-(void)loadScripts
{
    if (self.scriptsLoaded) {
        return;
    }
    self.scriptSet = [[NSMutableSet alloc] init];
    self.scriptDict = [[NSMutableDictionary alloc] init];
    
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:bundleRoot];
    
    NSString *filename;
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".nu"]) {
            [self loadNuScript:[bundleRoot stringByAppendingPathComponent:filename]];
        }
    }
    _scriptsLoaded = YES;
}

-(void)registerScript:(Class)script
{
    NSString *desc = [script description];
    if (desc && self.scriptDict[desc] == nil) {
        [self.scriptDict setObject:script forKey:desc];
    }
}

-(void)loadNuScript:(NSString *)location
{
    NSString *file = [NSString stringWithContentsOfFile:location encoding:NSUTF8StringEncoding error:nil];
    if (file != nil) {
        @try {
            NuCell *cell = [[Nu sharedParser] parse:[NSString stringWithContentsOfFile:location encoding:NSUTF8StringEncoding error:nil]];
            [[Nu sharedParser] eval:cell];
        }
        @catch (NSException *exception) {
            NSString *filename = [location lastPathComponent];
            NSLog(@"Recieved exception from Nu parser:\n'%@'\n when loading file '%@'", exception, filename);
            @throw exception;
        }
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

-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server
{
    for (RBScript *script in self.scriptSet) {
        [script messageLogged:message server:server];
    }
}

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server
{
    for (RBScript *script in self.scriptSet) {
        [script messageRecieved:message server:server];
    }
}

-(void)serverList:(RBServerViewController *)serverList didCreateNewServerCell:(UITableViewCell *)cell
{
    for (RBScript *script in self.scriptSet) {
        [script serverList:serverList didCreateNewServerCell:cell];
    }
}

-(void)serverList:(RBServerViewController *)serverList didCreateServerCell:(UITableViewCell *)cell forServer:(RBIRCServer *)server
{
    for (RBScript *script in self.scriptSet) {
        [script serverList:serverList didCreateServerCell:cell forServer:server];
    }
}

-(void)serverList:(RBServerViewController *)serverList didCreateChannelCell:(UITableViewCell *)cell forChannel:(RBIRCChannel *)channel
{
    for (RBScript *script in self.scriptSet) {
        [script serverList:serverList didCreateChannelCell:cell forChannel:channel];
    }
}

-(void)serverList:(RBServerViewController *)serverList didCreatePrivateCell:(UITableViewCell *)cell forPrivateConversation:(RBIRCChannel *)conversation
{
    for (RBScript *script in self.scriptSet) {
        [script serverList:serverList didCreatePrivateCell:cell forPrivateConversation:conversation];
    }
}

-(void)serverList:(RBServerViewController *)serverList didCreateNewChannelCell:(RBTextFieldServerCell *)cell
{
    for (RBScript *script in self.scriptSet) {
        [script serverList:serverList didCreateNewChannelCell:cell];
    }
}

@end
