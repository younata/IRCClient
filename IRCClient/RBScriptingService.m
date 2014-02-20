//
//  RBScriptingService.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBScriptingService.h"
#import "RBScript.h"

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
        scripts = [[NSMutableArray alloc] init];
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
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:bundleRoot];
    
    NSString *filename;
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".nu"]) {
            [Nu loadNuFile:filename fromBundleWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] withContext:nil];
        }
    }
}

-(NSArray *)scripts;
{
    return [NSArray arrayWithArray:scripts];
}

-(void)registerScript:(RBScript *)script
{
    [scripts addObject:script];
}

-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server
{
    for (RBScript *script in self.scripts) {
        [script messageLogged:message server:server];
    }
}

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server
{
    for (RBScript *script in self.scripts) {
        [script messageRecieved:message server:server];
    }
}

@end
