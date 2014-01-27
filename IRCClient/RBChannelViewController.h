//
//  RBChannelViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBServerVCDelegate.h"

@class RBIRCChannel;
@class RBServerViewController;
@class SWRevealViewController;

@interface RBChannelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, RBServerVCDelegate>

@property (nonatomic, strong) UITextField *input;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, weak) RBIRCChannel *channel;
@property (nonatomic, weak) RBServerViewController *serverView;
@property (nonatomic, weak) SWRevealViewController *revealController;

@end
