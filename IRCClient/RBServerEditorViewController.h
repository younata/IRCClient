//
//  RBServerEditorViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RBIRCServerDelegate.h"

@class RBIRCServer;

@interface RBServerEditorViewController : UIViewController <RBIRCServerDelegate, UITextFieldDelegate>

@property (nonatomic, weak) RBIRCServer *server;

@property (nonatomic, strong) UITextField *serverName;
@property (nonatomic, strong) UITextField *serverHostname;
@property (nonatomic, strong) UITextField *serverPort;
@property (nonatomic, strong) UISwitch *serverSSL;
@property (nonatomic, strong) UITextField *serverNick;
@property (nonatomic, strong) UITextField *serverRealName;
@property (nonatomic, strong) UITextField *serverPassword;
@property (nonatomic, strong) UISwitch *serverConnectOnStartup;

@property (nonatomic, strong) void (^onCancel)();

-(void)save;
-(void)dismiss;

@end
