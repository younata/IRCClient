//
//  RBServerViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerViewController.h"
#import "RBIRCServer.h"
#import "RBIRCChannel.h"
#import "RBIRCMessage.h"

#import "RBServerVCDelegate.h"
#import "RBServerEditorViewController.h"
#import "RBTextFieldServerCell.h"

#import "RBIRCServerDelegate.h"

#import "RBConfigurationKeys.h"

@interface RBServerViewController ()

@end

static NSString *CellIdentifier = @"Cell";
static NSString *textFieldCell = @"textFieldCell";

@implementation RBServerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.servers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Servers";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[RBTextFieldServerCell class] forCellReuseIdentifier:textFieldCell];
    
    [self.revealController setDelegate:self];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
}

-(void)setServers:(NSMutableArray *)servers
{
    for (RBIRCServer *server in _servers) {
        for (id<RBIRCServerDelegate> del in server.delegates) {
            [server rmDelegate:self];
        }
    }
    _servers = servers;
    for (RBIRCServer *server in servers) {
        [server addDelegate:self];
    }
}

-(void)saveServerData
{
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.servers];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.servers count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == [self.servers count]) {
        return 1;
    }
    RBIRCServer *server = self.servers[section];
    return [server sortedChannelKeys].count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBIRCServer *server = nil;
    NSArray *channels = nil;
    if (section < [self.servers count]) {
        server = self.servers[section];
        channels = [server sortedChannelKeys];
    }
    
    if (server != nil && row == channels.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:textFieldCell forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    if (!server) {
        cell.textLabel.text = NSLocalizedString(@"New Server", nil);
    } else {
        cell.textLabel.textColor = server.connected ? [UIColor darkTextColor] : [[UIColor darkTextColor] colorWithAlphaComponent:0.5];
        if (row == channels.count) {
            RBTextFieldServerCell *c = (RBTextFieldServerCell *)cell;
            c.textField.placeholder = NSLocalizedString(@"Join a channel", nil);
            c.data = server;
            c.textField.delegate = self;
            cell = c;
        } else {
            cell.textLabel.text = channels[row];
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.servers.count)
        return NO;
    NSString *channelName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    if ([channelName isEqualToString:RBIRCServerLog])
        return NO;
    return YES;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.servers.count)
        return UITableViewCellEditingStyleNone;
    NSString *channelName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    if ([channelName isEqualToString:RBIRCServerLog])
        return UITableViewCellEditingStyleNone;
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;
    NSInteger section = indexPath.section;
    if (section == self.servers.count)
        return;
    RBIRCServer *server = self.servers[section];
    NSInteger row = indexPath.row;
    if (row == 0) {
        [server quit];
        [self.servers removeObject:server];
    } else {
        NSString *channelName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
        if ([channelName isEqualToString:RBIRCServerLog])
            return;
        if (([channelName hasPrefix:@"#"] || [channelName hasPrefix:@"&"])) {
            [server part:channelName];
        }
        server[channelName] = nil;
    }
    [self saveServerData];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBServerEditorViewController *editor = nil;
    __weak RBServerViewController *theSelf = self;
    
    if (section < [self.servers count]) {
        RBIRCServer *server = self.servers[section];
        NSArray *channels = [server sortedChannelKeys];
        if (row != 0 && row < channels.count) {
            NSString *ch = channels[row];
            RBIRCChannel *channel = server[ch];
            [self.delegate server:server didChangeChannel:channel];
        } else if (row == 0) {
            editor = [[RBServerEditorViewController alloc] init];
            editor.server = server;
            editor.onCancel = ^{
                [theSelf.tableView reloadData];
                [theSelf saveServerData];
            };
        }
    } else {
        editor = [[RBServerEditorViewController alloc] init];
        RBIRCServer *newServer = [[RBIRCServer alloc] init];
        [editor setServer:newServer];
        [self.servers addObject:newServer];
        __weak RBServerEditorViewController *theEditor = editor;
        editor.onCancel = ^{
            if (!(theEditor.server.connected || theEditor.server.readStream.streamStatus != NSStreamStatusOpening)) {
                [theSelf.servers removeObject:theEditor.server];
            }
            [theSelf.tableView reloadData];
            [theSelf saveServerData];
        };
    }
    if (editor) {
        [self presentViewController:editor animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text == nil || [textField.text isEqualToString:@""])
        return YES;
    for (UITableViewCell *c in self.tableView.visibleCells) {
        if (![c isKindOfClass:[RBTextFieldServerCell class]])
            continue;
        RBTextFieldServerCell *cell = (RBTextFieldServerCell*)c;
        UITextField *tf = [cell textField];
        if ([tf.text isEqualToString:textField.text]) {
            RBIRCServer *server = cell.data;
            NSString *str = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [server join:str];
            [self.delegate server:server didChangeChannel:server[str]];
            [self.tableView reloadData];
            
            [self saveServerData];
        }
    }
    textField.text = @"";
    return YES;
}

#pragma mark - RBIRCServerDelegate

-(void)IRCServerDidConnect:(RBIRCServer *)server
{
    NSLog(@"%@ - %@", server.serverName, server.connected ? @"Connected" : @"Not Connected");
    [self.tableView reloadData];
}

-(void)IRCServer:(RBIRCServer *)server handleMessage:(RBIRCMessage *)message
{
    NSString *to = message.targets[0];
    if ((![server[to] isChannel] || message.command == IRCMessageTypeJoin)) {
        [self.tableView reloadData];
    }
}

#pragma mark - SWRevealControllerDelegate

-(void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    CGRect r = self.view.frame;
    r.size.width = revealController.rearViewRevealWidth;
    self.view.frame = r;
    self.navigationController.view.frame = r;
    [self.view layoutSubviews];
    [self.tableView reloadData];
}

@end
