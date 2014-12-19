//
//  RBServerEditorController.h
//  IRCClient
//
//  Created by Rachel Brindle on 12/17/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCServer;

@interface RBServerEditorViewController : UITableViewController

@property (nonatomic, weak) RBIRCServer *server;

@property (nonatomic, strong) UIBarButtonItem *helpButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *realname;
@property (nonatomic, strong) NSString *password;
@property (nonatomic) BOOL ssl;

@property (nonatomic, strong) void (^onCancel)();

- (void)showHelp;
- (void)dismiss;
- (void)save;

- (BOOL)validateInfo;

@end
