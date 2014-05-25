//
//  RBChannelViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCServer;
@class RBIRCMessage;
@class RBServerViewController;
@class SWRevealViewController;

@class HTAutocompleteTextField;

@interface RBChannelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) HTAutocompleteTextField *input;
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
-(void)serverViewChangedChannel:(NSNotification *)note;
-(void)serverViewDidDisconnectServer:(NSNotification *)note;
-(void)serverViewDidDisconnectChannel:(NSNotification *)note;

@end
