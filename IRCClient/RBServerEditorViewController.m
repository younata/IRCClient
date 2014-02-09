//
//  RBServerEditorViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerEditorViewController.h"

#import "RBConfigurationKeys.h"

#import "RBIRCServer.h"
#import "NSString+isNilOrEmpty.h"

@interface RBServerEditorViewController ()

@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) UIScrollView *scrollView;

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
    
    self.originalFrame = self.view.frame;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.scrollView];
    self.scrollView.scrollEnabled = YES;
    
    CGFloat width = self.view.frame.size.width / 2;
    
    CGFloat h = 40.0;
    
    CGFloat w = 480.0;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        w = 280.0;
        self.scrollView.contentSize = self.view.frame.size;
    }
    
    CGFloat w2 = w / 2;
    
    CGFloat y = 100;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(width - w2, 40, w, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"New Server";
    [self.scrollView addSubview:label];
    
    self.serverName = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y, w, h)];
    self.serverHostname = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + (h + 20), w, h)];
    self.serverPort = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 2 * (h + 20), w, h)];
    
    UILabel *sslLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - w2, y + 3 * (h + 20), 120, h)];
    sslLabel.text = @"Use SSL?";
    sslLabel.textAlignment = NSTextAlignmentLeft;
    [self.scrollView addSubview:sslLabel];
    
    self.serverSSL = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGFloat uiswidth = self.serverSSL.frame.size.width;
    self.serverSSL.frame = CGRectMake(width + (w2 - uiswidth), y + 3 * (h + 20), uiswidth, h);
    
    self.serverNick = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 4 * (h + 20), w, h)];
    self.serverRealName = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 5 * (h + 20), w, h)];
    self.serverPassword = [[UITextField alloc] initWithFrame:CGRectMake(width - w2, y + 6 * (h + 20), w, h)];
    self.serverPassword.secureTextEntry = YES;
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveButton.frame = CGRectMake(width + 10, y + 7 * (h + 20) - 20, 90, 80);
    [self.saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(width - 100, y + 7 * (h + 20) - 20, 90, 80);
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
        self.serverSSL.on = self.server.useSSL;
        label.text = @"Edit Server";
    } else {
        [self.saveButton setTitle:@"Connect" forState:UIControlStateNormal];
        self.serverSSL.on = YES;
    }
    self.serverName.placeholder = @"ServerName";
    self.serverHostname.placeholder = @"irc.freenode.net";
    self.serverPort.placeholder = @"6697";
    self.serverNick.placeholder = @"username";
    self.serverRealName.placeholder = @"iOS";
    self.serverPassword.placeholder = @"****";
    
    self.serverName.text = self.server.serverName;
    self.serverHostname.text = self.server.hostname;
    self.serverPort.text = self.server.port;
    self.serverNick.text = self.server.nick;
    self.serverRealName.text = self.server.realname;
    self.serverPassword.text = self.server.password;
    
    for (UITextField *tf in @[self.serverName,
                              self.serverHostname,
                              self.serverPort,
                              self.serverNick,
                              self.serverRealName,
                              self.serverPassword]) {
        [tf setBorderStyle:UITextBorderStyleLine];
        [tf setDelegate:self];
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
        [self.scrollView addSubview:v];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:self.onCancel];
}

- (void)save
{
    NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers]];
    NSMutableArray *marr = [[NSMutableArray alloc] init];
    for (RBIRCServer *s in arr) {
        if (![self.server isEqual:s]) {
            [marr addObject:s];
        }
    }
    
    self.server.serverName = self.serverName.text;
    self.server.nick = self.serverNick.text;
    if (![self.server.nick hasContent]) {
        self.serverNick.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"A username is required" attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
        return; // need a nick.
    }
    
    if (![self.server.serverName hasContent]) {
        self.server.serverName = self.serverHostname.text;
        if (![self.server.serverName hasContent]) {
            self.server.serverName = self.serverHostname.placeholder;
        }
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
    
    [marr addObject:self.server];
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:marr];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
    
    [self dismiss];
}



-(NSInteger)getKeyboardHeight:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    NSInteger keyboardHeight = keyboardFrameBeginRect.size.height;
    return keyboardHeight;
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25 animations:^{
        self.view.frame = self.originalFrame;
        self.scrollView.frame = self.view.frame;
    }];
}

-(void)keyboardDidShow:(NSNotification *)notification
{
    NSInteger kh = [self getKeyboardHeight:notification];
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat height = self.originalFrame.size.height - kh;
        
        self.view.frame = CGRectMake(0, 0, self.originalFrame.size.width, height);
        
        self.scrollView.frame = self.view.frame;
    }];
}
@end
