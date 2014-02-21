//
//  RBScript.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/20/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBScript.h"
#import "RBScriptingService.h"

#import "Nu.h"

@implementation RBScript

+(NSString *)description
{
    return NSStringFromClass(self);
}

+(id)inheritedByClass:(NuClass *)newClass
{
    [[RBScriptingService sharedInstance] registerScript:[newClass wrappedClass]];
    return [[self superclass] inheritedByClass:newClass];
}

-(void)messageRecieved:(RBIRCMessage *)message server:(RBIRCServer *)server{}
-(void)messageLogged:(RBIRCMessage *)message server:(RBIRCServer *)server{}

@end
