//
//  RBScript.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBScript.h"
#import "RBScriptingService.h"

@implementation RBScript

-(instancetype)init
{
    if ((self = [super init])) {
        [[RBScriptingService sharedInstance] registerScript:self];
    }
    return  self;
}

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server{}
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server{}

@end
