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
#import "NSString+contains.h"
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

#import "RBTextViewCell.h"

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
    [self.tableView registerClass:[RBTextViewCell class] forCellReuseIdentifier:CellIdentifier];
    
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
    
    NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigFontName];
    if (!fontName) {
        fontName = @"Inconsolata";
        [[NSUserDefaults standardUserDefaults] setObject:fontName forKey:RBConfigFontName];
    }
    double fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey:RBConfigFontSize];
    if (fontSize == 0) {
        fontSize = 14.0;
        [[NSUserDefaults standardUserDefaults] setDouble:fontSize forKey:RBConfigFontSize];
    }
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
    if (!font) {
        font = [UIFont systemFontOfSize:fontSize];
    }
    self.input.font = font;
    
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
    
    for (NSString *str in @[RBIRCServerConnectionDidDisconnect,
                            RBIRCServerErrorReadingFromStream,
                            RBIRCServerInvalidCommand,
                            RBIRCServerHandleMessage,
                            RBIRCServerUpdateMessage]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:str object:nil];
    }
}

-(void)handleNotification:(NSNotification *)note
{
    NSString *name = note.name;
    if ([name isEqualToString:RBIRCServerConnectionDidDisconnect]) {
        [self IRCServerConnectionDidDisconnect:note.object];
    } else if ([name isEqualToString:RBIRCServerErrorReadingFromStream]) {
        [self IRCServer:note.object errorReadingFromStream:note.userInfo[@"error"]];
    } else if ([name isEqualToString:RBIRCServerInvalidCommand]) {
        [self IRCServer:note.object invalidCommand:note.userInfo[@"error"]];
    } else if ([name isEqualToString:RBIRCServerHandleMessage]) {
        [self IRCServer:note.object handleMessage:note.userInfo[@"message"]];
    } else if ([name isEqualToString:RBIRCServerUpdateMessage]) {
        [self IRCServer:note.object updateMessage:note.userInfo[@"message"]];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return ret;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;
    NSAttributedString *as = [self attributedStringForIndex:i];
    RBTextViewCell *ret = (RBTextViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([ret.textView.attributedText isEqualToAttributedString:as]) {
        return ret;
    }
    ret.textView.attributedText = as;
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
    BOOL addedToLog = NO;
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
            addedToLog = YES;
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
            addedToLog = YES;
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
        addedToLog = YES;
    }
    
    textField.text = @"";
    
    if (addedToLog) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self tableView:self.tableView numberOfRowsInSection:0] - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        [self.tableView scrollToBottom:YES];
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
    [self.server[self.channel] read];
    [newChannel read];
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
    for (NSString *to in message.targets) {
        if ([to isEqualToString:self.channel]) {
            if (message.command == IRCMessageTypeTopic) {
                [(RBNameViewController *)self.revealController.rightViewController setTopic:message.message];
            }
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self tableView:nil numberOfRowsInSection:0] - 1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            if (![self.tableView scrollToBottomIfNear]) {
                // make a check to make sure that we're not scrolling because the log is short enough to display everything without scrolling...
                NSInteger sectionNum = [self.tableView numberOfSections] - 1;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:sectionNum] - 1 inSection:sectionNum];
                NSArray *ips = [self.tableView indexPathsForVisibleRows];
                
                BOOL show = YES;
                
                
                for (NSIndexPath *indexPath in ips) {
                    if ([indexPath isEqual:ip]) {
                        show = NO;
                    }
                }
                if (show) {
                    [self notifyUserOfMoreMessages];
                }
            }
        } else {
        }
    }
}

-(void)notifyUserOfMoreMessages
{
    NSArray *subviews = self.tableView.subviews;
    UIButton *button = nil;
    NSString *txt = @"1 new message\n(Touch to scroll down)";
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)view;
            NSAttributedString *as = [b attributedTitleForState:UIControlStateNormal];
            if ([as.string containsSubstring:@"new message"]) {
                NSArray *substrs = [as.string componentsSeparatedByString:@" "];
                NSString *str = [substrs firstObject];
                NSInteger nm = [str integerValue] + 1;
                
                txt = [NSString stringWithFormat:@"%ld new messages\n(Touch to scroll down)", (long)nm];
                button = b;
            }
        }
    }
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:txt attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor],
                                                                                           NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]}];
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width * 0.75, CGFLOAT_MAX)
                                             options:options
                                             context:nil];
    boundingRect.origin.y = self.tableView.frame.size.height * 0.25;
    boundingRect.origin.x = (self.tableView.frame.size.width * 0.5) - (boundingRect.size.width / 2.0);
    CGRect frame = CGRectInset(boundingRect, -10, -10);
    
    if (button == nil) {
        button = [UIButton systemButtonWithFrame:frame];
        button.titleLabel.numberOfLines = 0;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.backgroundColor = [UIColor blackColor];
        button.layer.shadowColor = button.backgroundColor.CGColor;
        button.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        button.layer.shadowRadius = 5.0;
        button.layer.shadowOpacity = 1.0 ;
        button.layer.masksToBounds = NO;
        button.layer.cornerRadius = 5;
        
        [button addTarget:self action:@selector(removeNewMessagesButtonAndScrollToBottom) forControlEvents:UIControlEventTouchUpInside];
        
        [self performSelector:@selector(removeNewMessagesButtonIfThere) withObject:nil afterDelay:5];
        
        button.alpha = 0.0;
        [self.tableView addSubview:button];
        [UIView animateWithDuration:0.1 animations:^{button.alpha = 1.0;}];
        
    } else {
        button.frame = frame;
    }
    
    [button setAttributedTitle:text forState:UIControlStateNormal];
}

-(void)removeNewMessagesButtonIfThere
{
    NSArray *subviews = self.tableView.subviews;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)view;
            NSAttributedString *as = [b attributedTitleForState:UIControlStateNormal];
            if ([as.string containsSubstring:@"new message"]) {
                [UIView animateWithDuration:0.2 animations:^{view.alpha = 0.0;} completion:^(BOOL finished){[view removeFromSuperview];}];
            }
        }
    }
}

-(void)removeNewMessagesButtonAndScrollToBottom
{
    [self removeNewMessagesButtonIfThere];
    [self.tableView scrollToBottom];
}

-(void)IRCServer:(RBIRCServer *)server updateMessage:(RBIRCMessage *)message
{
    for (NSString *to in message.targets) {
        if ([to isEqualToString:self.channel]) {
            NSUInteger i = [[self.server[self.channel] log] indexOfObject:message];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
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
