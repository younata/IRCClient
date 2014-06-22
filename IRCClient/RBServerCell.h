//
//  RBServerCell.h
//  IRCClient
//
//  Created by Rachel Brindle on 6/21/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCServer;

@interface RBServerCell : UITableViewCell

@property (nonatomic, strong) UIButton *reconnectButton;
@property (nonatomic, weak) RBIRCServer *server;

@end
