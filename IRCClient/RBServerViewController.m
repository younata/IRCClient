//
//  RBServerViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBServerViewController.h"
#import "RBIRCServer.h"

#import "RBServerVCDelegate.h"
#import "RBServerEditorViewController.h"
#import "RBTextFieldServerCell.h"

#import "RBIRCServerDelegate.h"

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
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[RBTextFieldServerCell class] forCellReuseIdentifier:textFieldCell];
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
    return [server.channels count] + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section < [self.servers count] && row == ([[self.servers[section] channels] count] + 1)) {
        cell = [tableView dequeueReusableCellWithIdentifier:textFieldCell forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    if (section == [self.servers count]) {
        cell.textLabel.text = @"New Server";
    } else {
        RBIRCServer *server = self.servers[section];
        NSArray *channels = [server.channels allKeys];
        if (row != 0 && row != [server.channels count] + 1) {
            cell.textLabel.text = channels[row - 1];
        } else if (row == 0) {
            cell.textLabel.text = server.serverName;
        } else {
            RBTextFieldServerCell *c = (RBTextFieldServerCell *)cell;
            c.textField.placeholder = @"Join a channel";
            c.data = server;
            c.textField.delegate = self;
        }
    }
    
    return cell;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == self.servers.count)
        return @"";
    return [self.servers[section] serverName];
}
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section != self.servers.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBServerEditorViewController *editor = nil;
    
    if (section < [self.servers count]) {
        RBIRCServer *server = self.servers[section];
        if (row != 0 && row <= server.channels.count) {
            NSArray *channels = [server.channels allKeys];
            NSString *ch = channels[row - 1];
            RBIRCChannel *channel = server[ch];
            [self.delegate server:server didChangeChannel:channel];
        } else if (row > server.channels.count) {
            ;
        } else {
            editor = [[RBServerEditorViewController alloc] init];
            editor.server = server;
        }
    } else {
        editor = [[RBServerEditorViewController alloc] init];
        RBIRCServer *newServer = [[RBIRCServer alloc] init];
        [editor setServer:newServer];
        [self.servers addObject:newServer];
        __weak RBServerEditorViewController *theEditor = editor;
        __weak RBServerViewController *theSelf = self;
        editor.onCancel = ^{
            if (!(theEditor.server.connected || theEditor.server.readStream.streamStatus == NSStreamStatusOpening)) {
                [theSelf.servers removeObject:theEditor.server];
            }
            [self.tableView reloadData];
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
            [server join:textField.text];
            [self.delegate server:server didChangeChannel:server[textField.text]];
        }
    }
    return YES;
}

#pragma mark - RBIRCServerDelegate

-(void)IRCserverDidConnect:(RBIRCServer *)server
{
    
}

@end
