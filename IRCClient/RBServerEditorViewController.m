//
//  RBServerEditorViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerEditorViewController.h"

#import "RBIRCServer.h"
#import "NSString+isNilOrEmpty.h"

@interface RBServerEditorViewController ()

@end

@implementation RBServerEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:sv];
    sv.scrollEnabled = YES;
    
    CGFloat width = self.view.frame.size.width / 2;
    
    CGFloat h = 40.0;
    
    CGFloat w = 480.0;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        w = 280.0;
        sv.contentSize = CGSizeMake(self.view.frame.size.width, 800);
    }
    
    CGFloat w2 = w / 2;
    
    CGFloat y = 100;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(width - w2, 40, w, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"New Server";
    [sv addSubview:label];
    
    self.serverName = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y, w, h)];
    self.serverHostname = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + (h + 20), w, h)];
    self.serverPort = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 2 * (h + 20), w, h)];
    
    UILabel *sslLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - w2, y + 3 * (h + 20), 120, h)];
    sslLabel.text = @"Use SSL?";
    sslLabel.textAlignment = NSTextAlignmentLeft;
    [sv addSubview:sslLabel];
    
    self.serverSSL = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGFloat uiswidth = self.serverSSL.frame.size.width;
    self.serverSSL.frame = CGRectMake(width + (w2 - uiswidth), y + 3 * (h + 20), uiswidth, h);
    
    self.serverNick = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 4 * (h + 20), w, h)];
    self.serverRealName = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 5 * (h + 20), w, h)];
    self.serverPassword = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 6 * (h + 20), w, h)];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveButton.frame = CGRectMake(width + 10, y + 7 * (h + 20), 90, 80);
    [self.saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(width - 100, y + 7 * (h + 20), 90, 80);
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.server.connected) {
        [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
        for (UIControl *c in @[self.serverHostname,
                               self.serverPort,
                               self.serverSSL,
                               self.serverRealName,
                               self.serverPassword]) {
            [c setEnabled:NO];
        }
        self.serverName.text = self.server.serverName;
        self.serverHostname.text = self.server.hostname;
        self.serverPort.text = self.server.port;
        self.serverSSL.on = self.server.useSSL;
        self.serverNick.text = self.server.nick;
        self.serverRealName.text = self.server.realname;
        self.serverPassword.text = self.server.password;
        label.text = @"Edit Server";
    } else {
        [self.saveButton setTitle:@"Connect" forState:UIControlStateNormal];
        //UIColor *color = [[UIColor darkTextColor] colorWithAlphaComponent:0.7];
        //self.serverName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Server Name" attributes:@{NSForegroundColorAttributeName: color}];
        self.serverName.placeholder = @"ServerName";
        self.serverHostname.placeholder = @"irc.freenode.net";
        self.serverPort.placeholder = @"6697";
        self.serverSSL.on = YES;
        self.serverNick.placeholder = @"username";
        self.serverRealName.placeholder = @"iOS";
        self.serverPassword.placeholder = @"****";
    }
    
    for (UITextField *tf in @[self.serverName,
                              self.serverHostname,
                              self.serverPort,
                              self.serverNick,
                              self.serverRealName,
                              self.serverPassword]) {
        [tf setBorderStyle:UITextBorderStyleLine];
        if (!self.server.connected) {
            UIColor *color = [[UIColor darkTextColor] colorWithAlphaComponent:0.7];
            [tf setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:tf.placeholder attributes:@{NSForegroundColorAttributeName: color}]];
        }
    }
    
    for (UIView *v in @[self.serverName,
                        self.serverHostname,
                        self.serverPort,
                        self.serverSSL,
                        self.serverNick,
                        self.serverRealName,
                        self.serverPassword,
                        self.saveButton,
                        self.cancelButton]) {
        [sv addSubview:v];
    }
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:self.onCancel];
}

- (void)save
{
    self.server.serverName = self.serverName.text;
    self.server.nick = self.serverNick.text;
    if (![self.server.nick hasContent]) {
        self.serverNick.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"A username is required" attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
        return; // need a nick.
    }
    
    if (![self.server.serverName hasContent]) {
        self.server.serverName = self.serverHostname.text;
    }
    
    if (!self.server.connected) {
        self.server.hostname = self.serverHostname.text;
        self.server.port = self.serverPort.text;
        self.server.useSSL = self.serverSSL.on;
        self.server.realname = self.serverRealName.text;
        self.server.password = self.serverPassword.text;
        
        if (![self.server.hostname hasContent]) {
            self.server.hostname = self.serverHostname.placeholder;
        }
        if (![self.server.port hasContent]) {
            self.server.port = self.serverPort.placeholder;
        }
        if (![self.server.realname hasContent]) {
            self.server.realname = self.serverRealName.placeholder;
        }
        
        [self.server connect];
    }
    [self dismiss];
}

@end
