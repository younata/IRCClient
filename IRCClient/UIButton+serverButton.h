//
//  UIButton+serverButton.h
//  IRCClient
//
//  Created by Rachel Brindle on 3/6/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCServer;

@interface UIButton (serverButton)

-(void)setServer:(RBIRCServer *)server;
-(RBIRCServer *)server;

@end
