//
//  RBChannelViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBServerVCDelegate.h"

@class RBIRCServer;
@class RBIRCMessage;
@class RBServerViewController;
@class SWRevealViewController;

@interface RBChannelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, RBServerVCDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITextField *input;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIButton *inputCommands;

@property (nonatomic, strong) UIActionSheet *actionSheet;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, weak) RBIRCServer *server;
@property (nonatomic, weak) RBServerViewController *serverView;
@property (nonatomic, weak) SWRevealViewController *revealController;

-(void)IRCServer:(RBIRCServer *)server handleMessage:(RBIRCMessage *)message;
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

-(void)disconnect;

// for specs.
-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server;

@end
