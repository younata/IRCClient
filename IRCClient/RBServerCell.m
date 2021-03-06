//
//  RBServerCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 6/21/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerCell.h"

#import "PureLayout.h"

#import "RBIRCServer.h"

@implementation RBServerCell

- (void)setServer:(RBIRCServer *)server
{
    _server = server;
    [self.reconnectButton removeFromSuperview];
    self.reconnectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.contentView addSubview:self.reconnectButton];
    self.reconnectButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.reconnectButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:8];
    [self.reconnectButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.reconnectButton setTitle:NSLocalizedString(@"Reconnect", nil) forState:UIControlStateNormal];
    [self.reconnectButton addTarget:self action:@selector(reconnectServer) forControlEvents:UIControlEventTouchUpInside];
}

- (void)reconnectServer
{
    [self.server reconnect];
}

@end
