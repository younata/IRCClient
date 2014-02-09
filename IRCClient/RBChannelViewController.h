//
//  RBChannelViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBServerVCDelegate.h"
#import "RBIRCServerDelegate.h"

@class RBIRCServer;
@class RBServerViewController;
@class SWRevealViewController;

@interface RBChannelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, RBIRCServerDelegate, RBServerVCDelegate>

@property (nonatomic, strong) UITextField *input;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, weak) RBIRCServer *server;
@property (nonatomic, weak) RBServerViewController *serverView;
@property (nonatomic, weak) SWRevealViewController *revealController;

@end
