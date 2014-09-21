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

#import "RBColorScheme.h"

#import "RBHelp.h"

#import "RBScriptingService.h"

@interface RBServerEditorViewController ()

@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) NSLayoutConstraint *keyboardConstraint;


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
    
    self.scrollView = [[UIScrollView alloc] initForAutoLayoutWithSuperview:self.view];
    [self.scrollView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    UIScrollView *sv = self.scrollView;
    self.scrollView.scrollEnabled = YES;
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.scrollView.contentSize = self.view.frame.size;
    }
    
    self.navigationItem.title = NSLocalizedString(@"New Server", nil);
    if ([self.server.serverName hasContent]) {
        self.navigationItem.title = NSLocalizedString(@"Edit Server", nil);
    }
    
    self.navigationController.navigationBar.tintColor = [RBColorScheme primaryColor];
    
    self.helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showHelp)];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:self.server.connected ? NSLocalizedString(@"Save", nil) : NSLocalizedString(@"Connect", nil)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(save)];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(dismiss)];
    
    self.navigationItem.rightBarButtonItems = @[self.saveButton, self.helpButton];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.serverName = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];
    [self.serverName autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
    [self.serverName autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [self.serverName autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:sv withOffset:-40];
    
    self.serverHostname = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];
    self.serverHostname.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.serverPort = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];
    
    UILabel *sslLabel = [[UILabel alloc] initForAutoLayoutWithSuperview:sv];
    sslLabel.text = NSLocalizedString(@"Use SSL?", nil);
    sslLabel.textAlignment = NSTextAlignmentLeft;
    
    self.serverSSL = [[UISwitch alloc] initForAutoLayoutWithSuperview:sv];
    self.serverSSL.on = NO;
    
    [sslLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.serverSSL withOffset:20];
    [self.serverSSL autoAlignAxis:ALAxisHorizontal toSameAxisOfView:sslLabel];
    [self.serverSSL autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:-20];
    
    self.serverNick = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];
    
    self.serverRealName = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];

    self.serverPassword = [[UITextField alloc] initForAutoLayoutWithSuperview:sv];
    self.serverPassword.secureTextEntry = YES;
    
    self.serverConnectOnStartup = [[UISwitch alloc] initForAutoLayoutWithSuperview:sv];
    self.serverConnectOnStartup.on = self.server.connectOnStartup;
    
    UILabel *connectOnStartupLabel = [[UILabel alloc] initForAutoLayoutWithSuperview:sv];
    connectOnStartupLabel.text = NSLocalizedString(@"Connect on startup?", nil);
    connectOnStartupLabel.textAlignment = NSTextAlignmentLeft;
    
    [connectOnStartupLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.serverConnectOnStartup withOffset:20];
    [connectOnStartupLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [self.serverConnectOnStartup autoAlignAxis:ALAxisHorizontal toSameAxisOfView:connectOnStartupLabel];
    [self.serverConnectOnStartup autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:-20];
    
    NSArray *views = @[self.serverName, self.serverHostname, self.serverPort, sslLabel, self.serverNick, self.serverRealName, self.serverPassword, connectOnStartupLabel];
    [views autoDistributeViewsAlongAxis:ALAxisVertical withFixedSpacing:20 alignment:NSLayoutFormatAlignAllLeft];
    [@[self.serverName, self.serverHostname, self.serverPort, self.serverNick, self.serverRealName, self.serverPassword] autoMatchViewsDimension:ALDimensionWidth];
    NSArray *switches = @[self.serverSSL, self.serverConnectOnStartup];
    [switches autoAlignViewsToEdge:ALEdgeRight];
    for (UIView *v in switches) {
        [v autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.serverName];
    }
    
    self.serverName.placeholder = NSLocalizedString(@"ServerName", nil);
    self.serverHostname.placeholder = @"irc.freenode.net";
    self.serverPort.placeholder = @"6667";
    self.serverNick.placeholder = NSLocalizedString(@"username", nil);
    self.serverRealName.placeholder = NSLocalizedString(@"realname", nil);
    self.serverPassword.placeholder = NSLocalizedString(@"server password", nil);
    
    self.serverName.text = self.server.serverName;
    self.serverHostname.text = self.server.hostname;
    self.serverPort.text = self.server.port;
    self.serverNick.text = self.server.nick;
    self.serverRealName.text = self.server.realname;
    self.serverPassword.text = self.server.password;
    
    [self.serverHostname setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    for (UITextField *tf in @[self.serverName,
                              self.serverHostname,
                              self.serverPort,
                              self.serverNick,
                              self.serverRealName,
                              self.serverPassword]) {
        [tf setBorderStyle:UITextBorderStyleLine];
        [tf setDelegate:self];
    }
    
    self.keyboardConstraint = [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    
    [self.view layoutSubviews];
    
    [[RBScriptingService sharedInstance] serverEditorWasLoaded:self];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
}

-(void)showHelp
{
    UINavigationController *nc = [[UINavigationController alloc] init];
    [nc pushViewController:[[RBHelpViewController alloc] init] animated:NO];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:self.onCancel];
    [[RBScriptingService sharedInstance] serverEditorWillBeDismissed:self];
}

-(void)save
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
        self.serverNick.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"A username is required", nil) attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
        return;
    }
    
    if (![self.server.serverName hasContent]) {
        self.server.serverName = self.serverHostname.text;
        if (![self.server.serverName hasContent]) {
            self.server.serverName = self.serverHostname.placeholder;
        }
    }
    
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
    
    if (!self.server.connected) {
        [self.server connect];
    } else {
        [self.server quit:@"Reloading settings"];
        [self.server connect];
    }
    
    [[RBScriptingService sharedInstance] serverEditor:self didMakeChangesToServer:self.server];
    
    [marr addObject:self.server];
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:marr];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
    
    [self dismiss];
}



-(CGFloat)getKeyboardHeight:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGFloat keyboardHeight;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        keyboardHeight = keyboardFrameBeginRect.size.width;
    } else {
        keyboardHeight = keyboardFrameBeginRect.size.height;
    }
    return keyboardHeight;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    CGFloat kh = [self getKeyboardHeight:notification];
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardConstraint.constant = -kh;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

@end
