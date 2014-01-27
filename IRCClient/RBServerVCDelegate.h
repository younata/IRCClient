//
//  RBServerVCDelegate.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RBIRCServer;
@class RBIRCChannel;

@protocol RBServerVCDelegate <NSObject>
@required
-(void)server:(RBIRCServer *)server didChangeChannel:(RBIRCChannel *)newChannel;

@end
