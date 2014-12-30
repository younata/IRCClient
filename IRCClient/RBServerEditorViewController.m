//
//  RBServerEditorController.m
//  IRCClient
//
//  Created by Rachel Brindle on 12/17/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerEditorViewController.h"

#import "RBIRCServer.h"
#import "RBColorScheme.h"
#import "RBScriptingService.h"
#import "RBHelp.h"
#import "RBConfigurationKeys.h"
#import "RBTextFieldServerCell.h"
#import "RBSwitchCell.h"

#import "RBDataManager.h"

@implementation RBServerEditorViewController

- (void)setServer:(RBIRCServer *)server
{
    _server = server;
    
    self.name = server.serverName;
    self.hostname = server.hostname;
    self.port = server.port;
    self.nick = server.nick;
    self.realname = server.realname;
    self.password = server.password;
    self.ssl = server.useSSL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [self validateInfo];
    
    [self.tableView registerClass:[RBTextFieldServerCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView registerClass:[RBSwitchCell class] forCellReuseIdentifier:@"switch"];
}

-(void)showHelp
{
    UINavigationController *nc = [[UINavigationController alloc] init];
    [nc pushViewController:[[RBHelpViewController alloc] init] animated:NO];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:self.onCancel];
    [[RBScriptingService sharedInstance] serverEditorWillBeDismissed:(RBServerEditorViewController*)self]; // FIXME: update RBScriptingService
}

- (void)save
{
    if (self.saveButton.enabled == NO) {
        return;
    }
    
    if (![self.realname hasContent]) {
        self.realname = self.nick;
    }
    if (![self.port hasContent]) {
        self.port = @"6667";
    }
    if (![self.hostname hasContent]) {
        self.hostname = @"irc.freenode.net";
    }
    if (![self.name hasContent]) {
        self.name = self.hostname;
    }
    
    self.server.serverName = self.name;
    self.server.nick = self.nick;
    self.server.hostname = self.hostname;
    self.server.port = self.port;
    self.server.useSSL = self.ssl;
    self.server.realname = self.realname;
    self.server.password = self.password;
    
    if (!self.server.connected) {
        [self.server connect];
    } else {
        [self.server quit:@"Reloading Settings"];
        [self.server connect];
    }
    
    [[[[RBDataManager sharedInstance] serverMatchingIRCServer:self.server] managedObjectContext] save:nil];
    
    [[RBScriptingService sharedInstance] serverEditor:(RBServerEditorViewController*)self didMakeChangesToServer:self.server];

    [self dismiss];
}

- (BOOL)validateInfo
{
    BOOL isValid = YES;
    NSCharacterSet *set = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x7F - 0x21)];
    
    self.hostname = self.hostname ?: @"";
    self.nick = self.nick ?: @"";
    self.realname = self.realname ?: @"";
    self.password = self.password ?: @"";
    for (NSString *text in @[self.nick, self.realname, self.password]) {
        if ([[text stringByTrimmingCharactersInSet:set] hasContent]) {
            isValid = NO;
            break;
        }
    }
    if (!self.nick.hasContent) {
        isValid = NO;
    }
    if (self.port.integerValue > 65535 || self.port.integerValue < 1) {
        isValid = NO;
    }
    self.saveButton.enabled = isValid;
    
    return isValid;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Server Name", nil);
        case 1:
            return NSLocalizedString(@"Hostname to connect to", nil);
        case 2:
            return NSLocalizedString(@"Port to connect to", nil);
        case 3:
            return NSLocalizedString(@"Use Secure Connection?", nil);
        case 4:
            return NSLocalizedString(@"Username", nil);
        case 5:
            return NSLocalizedString(@"realname (leave blank to use username)", nil);
        case 6:
            return NSLocalizedString(@"password (if required)", nil);
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 32;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section == 3) {
        RBSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch" forIndexPath:indexPath];
        cell.onSwitchChange = ^(BOOL change){self.ssl = change;};
        cell.theSwitch.on = self.ssl;
        cell.textLabel.text = NSLocalizedString(@"Use SSL/TLS?", nil);
        [cell.contentView bringSubviewToFront:cell.theSwitch];
        return cell;
    } else {
        RBTextFieldServerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        
        cell.textField.backgroundColor = [UIColor clearColor];
        cell.textField.placeholder = @"";
        cell.textField.text = @"";
        cell.onTextChange = ^(NSString *text) {};
        
        __weak RBTextFieldServerCell *theCell = cell;
        
        UIColor *invalidColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        
        void (^invalidate)() = ^{
            theCell.textField.backgroundColor = invalidColor;
            self.saveButton.enabled = NO;
        };
        void (^checkForValid)() = ^{
            theCell.textField.backgroundColor = [UIColor clearColor];
            [self validateInfo];
        };
        
        switch (section) {
            case 0: {
                cell.textField.text = self.name;
                cell.textField.placeholder = NSLocalizedString(@"ServerName", nil);
                cell.onTextChange = ^(NSString *text) {
                    // No need to validate!
                    self.name = text;
                };
                break;
            } case 1: {
                cell.textField.text = self.hostname;
                cell.textField.placeholder = @"irc.freenode.net";
                cell.onTextChange = ^(NSString *text) {
                    // validate (how do?)
                    self.hostname = text;
                };
                break;
            } case 2: {
                cell.textField.text = self.port;
                cell.textField.placeholder = @"6667";
                cell.onTextChange = ^(NSString *text) {
                    // validate (must be an unsigned number less than 65536)
                    self.port = [NSString stringWithFormat:@"%ld", (long)text.integerValue];
                    if (text.integerValue > 65535 || text.integerValue < 1) {
                        checkForValid();
                    } else {
                        invalidate();
                    }
                };
                break;
            } case 4: {
                cell.textField.text = self.nick;
                cell.textField.placeholder = NSLocalizedString(@"username", nil);
                cell.onTextChange = ^(NSString *text) {
                    // validate (characters must be between 0x21 and 0x7F, inclusive)
                    self.nick = text;
                    if (!text.hasContent) {
                        invalidate();
                        return;
                    }
                    NSCharacterSet *set = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x7F - 0x21)];
                    if (![[text stringByTrimmingCharactersInSet:set] hasContent]) {
                        checkForValid();
                    } else {
                        invalidate();
                    }
                };
                break;
            } case 5: {
                cell.textField.text = self.realname;
                cell.textField.placeholder = NSLocalizedString(@"realname", nil);
                cell.onTextChange = ^(NSString *text) {
                    // validate (characters must be between 0x21 and 0x7F, inclusive)
                    self.realname = text;
                    NSCharacterSet *set = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x7F - 0x21)];
                    if (![[text stringByTrimmingCharactersInSet:set] hasContent]) {
                        checkForValid();
                    } else {
                        invalidate();
                    }
                };
                break;
            } case 6: {
                cell.textField.text = self.password;
                cell.textField.placeholder = NSLocalizedString(@"server password", nil);
                cell.onTextChange = ^(NSString *text) {
                    // validate (characters must be between 0x21 and 0x7F, inclusive)
                    self.password = text;
                    NSCharacterSet *set = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x7F - 0x21)];
                    if (![[text stringByTrimmingCharactersInSet:set] hasContent]) {
                        checkForValid();
                    } else {
                        invalidate();
                    }
                };
                break;
            } default:
                break;
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = nil;
    for (UITableViewCell *c in tableView.visibleCells) {
        if ([[tableView indexPathForCell:c] isEqual:indexPath]) {
            cell = c;
            break;
        }
    }
    
    if (indexPath.section == 3) {
        RBSwitchCell *sw = (RBSwitchCell *)cell;
        sw.theSwitch.on = !sw.theSwitch.on;
    } else {
        RBTextFieldServerCell *tf = (RBTextFieldServerCell *)cell;
        [tf.textField becomeFirstResponder];
    }
}

@end
