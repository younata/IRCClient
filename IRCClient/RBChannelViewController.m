//
//  RBChannelViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBChannelViewController.h"

#import "UIButton+buttonWithFrame.h"

#import "RBIRCServer.h"
#import "RBIRCChannel.h"
#import "RBIRCMessage.h"
#import "SWRevealViewController.h"
#import "RBConfigViewController.h"

@interface RBChannelViewController ()
@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) UIView *borderView;

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
    
    
    //self.navigationItem.leftBarButtonItem.tintColor = [UIColor blackColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showSettings)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height-inputHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // bunch of view shit to make the interface look not-shit.
    self.borderView = [[UIView alloc] initWithFrame:CGRectMake(0, height - inputHeight, width, inputHeight)];
    self.borderView.backgroundColor = [UIColor blackColor];
    UIView *inputView = [[UIView alloc] initWithFrame:CGRectMake(0, 1, width, inputHeight - 1)];
    inputView.backgroundColor = [UIColor whiteColor];
    [self.borderView addSubview:inputView];
    
    self.input = [[UITextField alloc] initWithFrame:CGRectMake(4, 0, width - 28, inputHeight - 1)];
    self.input.placeholder = NSLocalizedString(@"Message", nil);
    self.input.returnKeyType = UIReturnKeySend;
    self.input.backgroundColor = [UIColor whiteColor];
    self.input.delegate = self;
    
    self.inputCommands = [UIButton systemButtonWithFrame:CGRectMake(width - 24, 0, 20, inputHeight - 1)];
    [self.inputCommands setTitle:@"+" forState:UIControlStateNormal];
    self.inputCommands.titleLabel.font = [UIFont systemFontOfSize:20];
    [self.inputCommands addTarget:self action:@selector(showInputCommands) forControlEvents:UIControlEventTouchUpInside];
    [inputView addSubview:self.inputCommands];
    [inputView addSubview:self.input];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.borderView];
    
    [self revealButtonPressed:nil];
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

-(void)showInputCommands
{
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Commands", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    self.actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    
    for (NSString *str in @[@"notice", @"mode", @"kick", @"topic", @"nick", @"quit"]) {
        [self.actionSheet addButtonWithTitle:str];
    }
    
    UIActionSheet *as = self.actionSheet;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [as showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        UIButton *ic = self.inputCommands;
        CGRect rect = [ic frame];
        [as showFromRect:rect inView:self.view animated:YES];
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
        CGFloat height = self.originalFrame.size.height;
        CGFloat width = self.originalFrame.size.width;
        CGFloat inputHeight = 40;
        
        self.view.frame = self.originalFrame;
        self.tableView.frame = CGRectMake(0, 0, width, height - inputHeight);
        self.borderView.frame = CGRectMake(0, height - inputHeight, width, inputHeight);
    }];
}

-(void)keyboardDidShow:(NSNotification *)notification
{
    NSInteger kh = [self getKeyboardHeight:notification];
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat height = self.originalFrame.size.height - kh;
        CGFloat width = self.originalFrame.size.width;
        CGFloat inputHeight = 40;
        
        self.view.frame = CGRectMake(0, 0, self.originalFrame.size.width, height);
        
        self.tableView.frame = CGRectMake(0, 0, width, height - inputHeight);
        self.borderView.frame = CGRectMake(0, height - inputHeight, width, inputHeight);
    }];
}

-(NSAttributedString *)attributedStringForIndex:(NSInteger)index
{
    if ([self.server[self.channel] log].count <= index)
        return nil;
    RBIRCMessage *msg = [[self.server[self.channel] log] objectAtIndex:index];
    NSString *str = [NSString stringWithFormat:@"%@: %@", msg.from, msg.message];
    if ([self.channel isEqualToString:RBIRCServerLog]) {
        str = msg.message;
    }
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}];
    return text;
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.server[self.channel] log] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *ret = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    ret.textLabel.attributedText = [self attributedStringForIndex:indexPath.row];
    ret.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    ret.textLabel.numberOfLines = 0;
    [ret layoutSubviews];
    //ret.textLabel.text = [msg message];
    //ret.detailTextLabel.text = [msg to];
    return ret;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.server[self.channel] log].count) {
        return 40.0;
    }
    
    NSAttributedString *text = [self attributedStringForIndex:indexPath.row];
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(self.view.frame.size.width, CGFLOAT_MAX)
                                             options:options
                                             context:nil];
    
    return boundingRect.size.height * 1.2;
}

#pragma mark - RBServerVCDelegate

-(void)server:(RBIRCServer *)server didChangeChannel:(RBIRCChannel *)newChannel
{
    [self.server rmDelegate:self];
    [server addDelegate:self];
    self.server = server;
    self.channel = newChannel.name;
    self.navigationItem.title = newChannel.name;
    [self.tableView reloadData];
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
        [self.tableView reloadData];
    }
    
    return YES;
}

#pragma mark - RBIRCServerDelegate

-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server
{
    // meh.
}

-(void)IRCServer:(RBIRCServer *)server errorReadingFromStream:(NSError *)error
{
    // meh.
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
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.server[self.channel] log].count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        } else {
            NSLog(@"'%@', '%@'", self.channel, message.debugDescription);
        }
    }
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet cancelButtonIndex] == buttonIndex)
        return;
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *str = [NSString stringWithFormat:@"/%@ ", title];
    
    self.input.text = [str stringByAppendingString:self.input.text];
}

@end
