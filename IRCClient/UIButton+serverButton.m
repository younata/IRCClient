//
//  UIButton+serverButton.m
//  IRCClient
//
//  Created by Rachel Brindle on 3/6/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "UIButton+serverButton.h"
#import "NSObject+customProperty.h"

#import "RBIRCServer.h"

static NSString *key = @"server";

@implementation UIButton (serverButton)

-(void)setServer:(RBIRCServer *)server
{
    [self setCustomProperty:server forKey:key];
}

-(RBIRCServer *)server
{
    return [self getCustomPropertyForKey:key];
}

@end
