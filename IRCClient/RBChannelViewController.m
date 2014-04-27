//
//  RBChannelViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBChannelViewController.h"

#import "UIButton+buttonWithFrame.h"
#import "NSString+isNilOrEmpty.h"
#import "UIView+initWithSuperview.h"

#import "RBIRCServer.h"
#import "RBIRCChannel.h"
#import "RBIRCMessage.h"
#import "SWRevealViewController.h"
#import "RBConfigViewController.h"
#import "RBConfigurationKeys.h"

#import "UITableView+Scroll.h"

#import "RBColorScheme.h"

#import "RBHelp.h"

#import "RBScriptingService.h"

#import "RBNameViewController.h"

#import "RBChordedKeyboard.h"

@interface RBChannelViewController ()
@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic) NSLayoutConstraint *keyboardConstraint;

@property (nonatomic, strong) NSMutableDictionary *cells;

@end

static NSString *CellIdentifier = @"Cell";

@implementation RBChannelViewController

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
	// Do any additional setup after loading the view.
    
    self.originalFrame = self.view.frame;
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat height = self.view.frame.size.height;
    CGFloat width = self.view.frame.size.width;
    
    CGFloat inputHeight = 40;
    
    [self.revealController panGestureRecognizer];
    [self.revealController tapGestureRecognizer];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(revealButtonPressed:)];
    
    
    //self.navigationItem.leftBarButtonItem.tintColor = [RBColorScheme primaryColor];
    self.navigationController.navigationBar.tintColor = [RBColorScheme primaryColor];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showSettings)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showHelp)];
    self.navigationItem.rightBarButtonItems = @[settingsButton, helpButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height-inputHeight) style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // bunch of view shit to make the interface look not-shit.
    self.borderView = [[UIView alloc] initForAutoLayoutWithSuperview:self.view];
    self.borderView.backgroundColor = [UIColor blackColor];
    
    [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.tableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.borderView];
    
    self.keyboardConstraint = [self.borderView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.borderView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.borderView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.borderView autoSetDimension:ALDimensionHeight toSize:inputHeight relation:NSLayoutRelationEqual];
    
    UIView *inputView = [[UIView alloc] initForAutoLayoutWithSuperview:self.borderView];
    inputView.backgroundColor = [UIColor whiteColor];
    [inputView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(1, 0, 0, 0)];
    
    self.input = [[UITextField alloc] initForAutoLayoutWithSuperview:inputView];
    self.input.placeholder = NSLocalizedString(@"Message", nil);
    self.input.returnKeyType = UIReturnKeySend;
    self.input.backgroundColor = [UIColor whiteColor];
    self.input.delegate = self;
    [self.input autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.input autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [self.input autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:4];
    
    self.inputCommands = [UIButton buttonWithType:UIButtonTypeSystem];
    self.inputCommands.translatesAutoresizingMaskIntoConstraints = NO;
    [inputView addSubview:self.inputCommands];
    [self.inputCommands setTitle:@"+" forState:UIControlStateNormal];
    self.inputCommands.titleLabel.font = [UIFont systemFontOfSize:20];
    [self.inputCommands addTarget:self action:@selector(showInputCommands) forControlEvents:UIControlEventTouchUpInside];
    
    [self.inputCommands autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.inputCommands autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.inputCommands autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [self.inputCommands autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.input];
    
    [self revealButtonPressed:nil];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.view addGestureRecognizer:tgr];
    
    UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwipe:)];
    sgr.numberOfTouchesRequired = 2;
    
    [[RBScriptingService sharedInstance] channelViewWasLoaded:self];
}

-(void)loadExtraKeyboards
{
    Class cls = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigKeyboard];
    if (cls == nil) {
        self.input.inputView = nil;
    } else if ([[[cls alloc] init] conformsToProtocol:@protocol(RBChordedKeyboardDelegate)]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad &&
            UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            RBChordedKeyboard *keyboard = [[RBChordedKeyboard alloc] init];
            keyboard.delegate = [[cls alloc] init];
            self.input.inputView = keyboard;
        } else {
            self.input.inputView = nil;
        }
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self loadExtraKeyboards];
}

-(void)tapped:(UITapGestureRecognizer *)tgr
{
    CGRect rect = CGRectInset(self.borderView.frame, 0, -4);
    CGPoint point = [tgr locationInView:self.view];
    if (CGRectContainsPoint(rect, point)) {
        [self.tableView scrollToBottom];
    }
}

-(void)twoFingerSwipe:(UISwipeGestureRecognizer *)sgr
{
    if (sgr.direction == UISwipeGestureRecognizerDirectionDown) {
        [self.tableView scrollToBottom];
    } else if (sgr.direction == UISwipeGestureRecognizerDirectionUp) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
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
    [self loadExtraKeyboards];
    
    if (!self.server.connected) {
        [self disconnect];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)showInputCommands
{
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Commands", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    self.actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    
    for (NSString *str in @[@"notice", @"mode", @"kick", @"topic", @"nick", @"quit", @"action", @"ctcp"]) {
        [self.actionSheet addButtonWithTitle:str];
    }
    
    UIActionSheet *as = self.actionSheet;
    [as showInView:self.view.superview];
    // https://www.dropbox.com/s/bxlbj0hwgtoe19u/2014-02-22%2000.06.28.png is ugly
    // but it's less ugly than the other options for ipad.
}

-(void)showCTCPCommands
{
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CTCP Commands", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    self.actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    
    for (NSString *str in @[@"finger",
                            @"version",
                            @"source",
                            @"userinfo",
                            @"clientinfo",
                            @"ping",
                            @"time"]) {
        [self.actionSheet addButtonWithTitle:str];
    }
    
    UIActionSheet *as = self.actionSheet;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [as showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [as showInView:self.view.superview];
    }
}

-(void)revealButtonPressed:(id)sender
{
    [self.input resignFirstResponder];
    [self.revealController revealToggle:sender];
}

-(void)showSettings
{
    [self.input resignFirstResponder];
    
    RBConfigViewController *cvc = [[RBConfigViewController alloc] init];
    
    UINavigationController *newNC = [[UINavigationController alloc] initWithRootViewController:cvc];
    [self presentViewController:newNC animated:YES completion:nil];
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
    } completion:^(BOOL finished){
        [self.tableView scrollToBottom:NO];
    }];
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
    } completion:^(BOOL finished){
        [self.tableView scrollToBottom:NO];
    }];
}

-(NSAttributedString *)attributedStringForIndex:(NSInteger)index
{
    if ([self.server[self.channel] log].count <= index)
        return nil;
    RBIRCMessage *msg = [[self.server[self.channel] log] objectAtIndex:index];
    return msg.attributedMessage;
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = [[self.server[self.channel] log] count];
    if (ret > 50) {
        return 50;
    }
    return ret;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;
    NSInteger length = [[self.server[self.channel] log] count];
    if (length > 50) {
        length -= 50;
        i = length + i;
    }
    NSAttributedString *as = [self attributedStringForIndex:i];
    UITableViewCell *ret = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITextView *tv = [[UITextView alloc] initForAutoLayoutWithSuperview:ret.contentView];
    [tv autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    tv.attributedText = as;
    tv.dataDetectorTypes = UIDataDetectorTypeLink;
    tv.editable = NO;
    tv.userInteractionEnabled = YES;
    tv.scrollEnabled = NO;
    tv.textContainerInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [ret layoutSubviews];
    return ret;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.server[self.channel] log].count) {
        return 40.0;
    }
    
    CGFloat indentionWidth = 20;
    NSAttributedString *text = [self attributedStringForIndex:indexPath.row];
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(self.view.frame.size.width - indentionWidth, CGFLOAT_MAX)
                                             options:options
                                             context:nil];
    
    return boundingRect.size.height + 10;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *str = textField.text;
    if ([str hasPrefix:@"/"]) {
        
        str = [str substringFromIndex:1];
        NSArray *c = [str componentsSeparatedByString:@" "];
        NSString *command = c[0];
        str = [[str substringFromIndex:[c[0] length]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        c = [str componentsSeparatedByString:@" "];
        if (c.count == 1 && [c[0] isEqualToString:@""]) {
            c = @[];
        }
        switch ([RBIRCMessage getMessageTypeForString:command]) {
            case IRCMessageTypeJoin:
                if (c.count > 1) {
                    [self.server join:c[0] Password:c[1]];
                } else {
                    [self.server join:c[0]];
                }
                break;
            case IRCMessageTypePart: {
                NSString *message = nil;
                if (c.count > 0)
                    message = c[0];
                [self.server part:self.channel message:message];
            }
            case IRCMessageTypePrivmsg:
                break;
            case IRCMessageTypeNotice:
                break;
            case IRCMessageTypeMode:
                [self.server mode:self.channel options:c];
                break;
            case IRCMessageTypeKick: {
                NSString *target = nil;
                NSString *reason = self.server.nick;
                if (c.count == 0)
                    break;
                if (c.count > 0)
                    target = c[0];
                if (c.count > 1)
                    reason = [str substringFromIndex:target.length + 1];
                [self.server kick:self.channel target:target reason:reason];
                break;
            }
            case IRCMessageTypeTopic:
                [self.server topic:self.channel topic:str];
                break;
            case IRCMessageTypeNick:
                if (c.count == 0)
                    break;
                [self.server nick:c[0]];
                break;
            case IRCMessageTypeOper:
                if (c.count < 2)
                    break;
                [self.server oper:c[0] password:c[1]];
                break;
            case IRCMessageTypeQuit: {
                NSString *reason = self.server.nick;
                if (c.count > 0)
                    reason = str;
                [self.server quit:reason];
                break;
            }
            default:
                break;
        }
        if ([command isEqualToString:@"ctcp"]) {
            NSString *target, *action;
            if (c.count > 1) {
                action = c[0];
                target = c[1];
            } else {
                target = self.channel;
                action = c[0];
            }
            NSString *cmd = [NSString stringWithFormat:@"PRIVMSG %@ :%c%@%c\r\n", target, 1, [action uppercaseString], 1];

            if ([[action uppercaseString] isEqualToString:@"PING"]) {
                double timestamp = [[NSDate date] timeIntervalSince1970];
                cmd = [NSString stringWithFormat:@"PRIVMSG %@ :%c%@ %f%c\r\n", target, 1, [action uppercaseString], timestamp, 1];
            }
            [self.server sendCommand:cmd];
            RBIRCMessage *msg = [[RBIRCMessage alloc] init];
            msg.from = self.server.nick;
            msg.targets = [@[target] mutableCopy];
            msg.message = action;
            msg.command = [RBIRCMessage getMessageTypeForString:action];
            msg.rawMessage = cmd;
            [[self.server[target] log] addObject:msg];
        } else if ([command isEqualToString:@"me"]) {
            NSString *action = [NSString stringWithFormat:@"PRIVMSG %@ :%cACTION %@%c\r\n", self.channel, 1, str, 1];
            [self.server sendCommand:action];
            RBIRCMessage *msg = [[RBIRCMessage alloc] init];
            msg.from = self.server.nick;
            msg.targets = [@[self.channel] mutableCopy];
            msg.message = [NSString stringWithFormat:@"* %@ %@", self.server.nick, str];
            msg.command = IRCMessageTypePrivmsg;
            msg.rawMessage = str;
            msg.attributedMessage = [[NSAttributedString alloc] initWithString:msg.message attributes:[msg defaultAttributes]];
            [[self.server[self.channel] log] addObject:msg];
        }
    } else {
        [self.server privmsg:self.channel contents:str];
        self.input.text = @"";
        RBIRCMessage *msg = [[RBIRCMessage alloc] init];
        msg.from = self.server.nick;
        msg.targets = [@[self.channel] mutableCopy];
        msg.message = str;
        msg.command = IRCMessageTypePrivmsg;
        msg.rawMessage = [NSString stringWithFormat:@"PRIVMSG %@ %@", msg.targets[0], str];
        [[self.server[self.channel] log] addObject:msg];
    }
    [self.tableView reloadData];
    
    textField.text = @"";
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if (rows != 0) {
        rows--;
    }
    if (rows != 0 && [self.tableView numberOfSections] != 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    return YES;
}

-(void)disconnect
{
    self.navigationItem.title = @"Disconnected";
    self.input.enabled = NO;
    self.inputCommands.enabled = NO;
    
    RBIRCChannel *oldChannel = self.server[self.channel];
    RBIRCServer *oldServer = self.server;
    
    self.channel = nil;
    self.server = nil;
    
    [self.tableView reloadData];
    
    [[RBScriptingService sharedInstance] channelView:self didDisconnectFromChannel:oldChannel andServer:oldServer];
}

-(void)connect
{
    self.input.enabled = YES;
    self.inputCommands.enabled = YES;
}

#pragma mark - RBServerVCDelegate

-(void)server:(RBIRCServer *)server didChangeChannel:(RBIRCChannel *)newChannel
{
    [self.server rmDelegate:self];
    [server addDelegate:self];
    self.server = server;
    self.channel = newChannel.name;
    self.navigationItem.title = newChannel.name;
    [self connect];
    if (!self.server.connected) {
        [self disconnect];
    }
    [self.tableView reloadData];
    [self.tableView scrollToBottom:NO];
    [[RBScriptingService sharedInstance] channelView:self didSelectChannel:self.server[self.channel] andServer:self.server];
    [(RBNameViewController *)self.revealController.rightViewController setTopic:newChannel.topic];
    [(RBNameViewController *)self.revealController.rightViewController setNames:newChannel.names];
}

#pragma mark - RBIRCServerDelegate

-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server
{
    if (![self.server isEqual:server]) {
        return;
    }
    [self disconnect];
}

-(void)IRCServer:(RBIRCServer *)server errorReadingFromStream:(NSError *)error
{
    [self IRCServerConnectionDidDisconnect:server];
}

-(void)IRCServer:(RBIRCServer *)server invalidCommand:(NSError *)error
{
    // meh.
}

-(void)IRCServer:(RBIRCServer *)server handleMessage:(RBIRCMessage *)message
{
    [self.tableView reloadData];
    for (NSString *to in message.targets) {
        if ([to isEqualToString:self.channel]) {
            if (message.command == IRCMessageTypeTopic) {
                [(RBNameViewController *)self.revealController.rightViewController setTopic:message.message];
            }
            BOOL shouldScroll = NO;
            NSInteger section = 0;
            NSInteger row = [self tableView:self.tableView numberOfRowsInSection:0] - 2; // -1 for index, another -1 because we just added to it.
            
            for (NSIndexPath *ip in [self.tableView indexPathsForVisibleRows]) {
                if (ip.section < section)
                    continue;
                else if (ip.section > section)
                    break;
                if (ip.row == row) {
                    shouldScroll = YES;
                    break;
                }
            }
            
            if (shouldScroll) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self tableView:self.tableView numberOfRowsInSection:0] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        } else {
            NSLog(@"'%@', '%@'", self.channel, message.debugDescription);
        }
    }
}

-(void)IRCServer:(RBIRCServer *)server updateMessage:(RBIRCMessage *)message
{
    for (NSString *to in message.targets) {
        if ([to isEqualToString:self.channel]) {
            [self.tableView reloadData];
            break;
        }
    }
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet cancelButtonIndex] == buttonIndex)
        return;
    NSString *str = @"";
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([actionSheet.title isEqualToString:NSLocalizedString(@"Commands", nil)]) {
        if ([title isEqualToString:@"action"])
            title = @"me";
        str = [NSString stringWithFormat:@"/%@ ", title];
        if ([title isEqualToString:@"ctcp"]) {
            [self showCTCPCommands];
        }
    } else if ([actionSheet.title isEqualToString:NSLocalizedString(@"CTCP Commands", nil)]) {
        str = [NSString stringWithFormat:@"/ctcp %@", title];
    }
    self.input.text = str;
}

@end
