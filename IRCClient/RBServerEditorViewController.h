//
//  RBServerEditorViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCServer;

@interface RBServerEditorViewController : UIViewController

@property (nonatomic, weak) RBIRCServer *server;

@property (nonatomic, strong) UITextField *serverName;
@property (nonatomic, strong) UITextField *serverHostname;
@property (nonatomic, strong) UITextField *serverPort;
@property (nonatomic, strong) UISwitch *serverSSL;
@property (nonatomic, strong) UITextField *serverNick;
@property (nonatomic, strong) UITextField *serverRealName;
@property (nonatomic, strong) UITextField *serverPassword;

@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) void (^onCancel)(void);

-(void)save;
-(void)dismiss;

@end
