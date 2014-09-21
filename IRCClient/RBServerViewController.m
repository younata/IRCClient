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

#import "RBServerEditorViewController.h"
#import "RBTextFieldServerCell.h"
#import "RBServerCell.h"

#import "RBConfigurationKeys.h"

#import "RBChannelViewController.h" // shouldn't have to do this...

#import "RBColorScheme.h"
#import "RBScriptingService.h"

@interface RBServerViewController ()
{
    RBIRCChannel *selectedChannel;
}

@property (nonatomic, strong) UIAlertView *av;

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
    
    self.navigationController.navigationBar.tintColor = [RBColorScheme secondaryColor];
    
    [self.tableView registerClass:[RBServerCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[RBTextFieldServerCell class] forCellReuseIdentifier:textFieldCell];
        
    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    [[RBScriptingService sharedInstance] serverListWasLoaded:self];
    
    for (NSString *str in @[RBIRCServerDidConnect,
                            RBIRCServerErrorReadingFromStream,
                            RBIRCServerHandleMessage,
                            RBIRCServerConnectionDidDisconnect]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:str object:nil];
    }
}

-(void)handleNotification:(NSNotification *)note
{
    NSString *name = note.name;
    if ([name isEqualToString:RBIRCServerDidConnect]) {
        [self IRCServerDidConnect:note.object];
    } else if ([name isEqualToString:RBIRCServerErrorReadingFromStream]) {
        [self IRCServer:note.object errorReadingFromStream:note.userInfo[@"error"]];
    } else if ([name isEqualToString:RBIRCServerHandleMessage]) {
        [self IRCServer:note.object handleMessage:note.userInfo[@"message"]];
    } else if ([name isEqualToString:RBIRCServerConnectionDidDisconnect]) {
        [self IRCServerConnectionDidDisconnect:note.object];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (RBIRCServer *server in self.servers) {
        if ([server connectOnStartup] && ![server connected] && [server.nick hasContent]) {
            [server reconnect];
        }
    }
}

-(void)saveServerData
{
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.servers];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
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
        cell.textLabel.text = [@"+ " stringByAppendingString:NSLocalizedString(@"New Server", nil)];
        cell.textLabel.textColor = [RBColorScheme primaryColor];
        [[RBScriptingService sharedInstance] serverList:self didCreateNewServerCell:cell];
    } else {
        cell.textLabel.textColor = server.connected ? [UIColor darkTextColor] : [[UIColor darkTextColor] colorWithAlphaComponent:0.5];
        if (row == channels.count) {
            RBTextFieldServerCell *c = (RBTextFieldServerCell *)cell;
            c.textField.placeholder = NSLocalizedString(@"Join a channel", nil);
            c.data = server;
            c.textField.delegate = self;
            [c layoutSubviews];
            cell = c;
            [[RBScriptingService sharedInstance] serverList:self didCreateNewChannelCell:c];
        } else {
            cell.textLabel.text = channels[row];
            RBIRCChannel *channel = server[channels[row]];
            
            if (![channel isEqual:selectedChannel]) {
                if (channel.unreadMessages.count != 0) {
                    cell.textLabel.text = [NSString stringWithFormat:@"[%lu] %@", (unsigned long)channel.unreadMessages.count, channel.name];
                }
            }
            
            if (row == 0) {
                cell.textLabel.textColor = [RBColorScheme primaryColor];
                [(RBServerCell *)cell setServer:server];
                [[RBScriptingService sharedInstance] serverList:self didCreateServerCell:cell forServer:server];
            } else if ([server[channels[row]] isChannel]) {
                cell.textLabel.textColor = [RBColorScheme secondaryColor];
                [[RBScriptingService sharedInstance] serverList:self didCreateChannelCell:cell forChannel:server[channels[row]]];
            } else {
                cell.textLabel.textColor = [RBColorScheme tertiaryColor];
                [[RBScriptingService sharedInstance] serverList:self didCreatePrivateCell:cell forPrivateConversation:server[channels[row]]];
            }
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

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *disconnect = NSLocalizedString(@"Disconnect", nil);
    NSString *part = NSLocalizedString(@"Part", nil);
    if (indexPath.row == 0)
        return disconnect;
    RBIRCServer *server = self.servers[indexPath.section];
    RBIRCChannel *channel = server[server.sortedChannelKeys[indexPath.row]];
    return channel.isChannel ? part : NSLocalizedString(@"Delete", nil);
    return indexPath.row == 0 ? disconnect : part;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:RBServerViewDidDisconnectServer object:server];
        if ([server connected]) {
            [server quit];
        }
        [self.servers removeObject:server];
    } else {
        NSString *channelName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
        if ([channelName isEqualToString:RBIRCServerLog])
            return;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RBServerViewDidDisconnectChannel object:@[server, channelName]];
        
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
    
    if (section < [self.servers count]) {
        RBIRCServer *server = self.servers[section];
        NSArray *channels = [server sortedChannelKeys];
        if (row != 0 && row < channels.count) {
            NSString *ch = channels[row];
            RBIRCChannel *channel = server[ch];
            selectedChannel = channel;
            [[NSNotificationCenter defaultCenter] postNotificationName:RBServerViewDidChangeChannel object:@{@"server": server, @"channel": channel}];
        } else if (row == 0) {
            editor = [self editorViewControllerWithOptions:@{@"server": server}];
        }
    } else {
        RBIRCServer *newServer = [[RBIRCServer alloc] init];
        [self.servers addObject:newServer];
        editor = [self editorViewControllerWithOptions:@{@"server": newServer}];
    }
    if (editor) {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:editor];
        [self presentViewController:nc animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(RBServerEditorViewController *)editorViewControllerWithOptions:(NSDictionary *)options
{
    RBServerEditorViewController *editor = [[RBServerEditorViewController alloc] init];
    
    [editor view];
    
    RBIRCServer *server = options[@"server"];
    if (!server) {
        server = [[RBIRCServer alloc] init];
    }
    if (server) {
        [editor setServer:server];
        
        editor.serverNick.text = server.nick;
        editor.serverPassword.text = server.password;
        editor.serverPassword.text = server.port;
        editor.serverHostname.text = server.hostname;
        editor.serverName.text = server.serverName;
        editor.serverSSL.on = server.useSSL;
        
        if (![self.servers containsObject:server]) {
            [self.servers addObject:server];
        }
    }
    if (options[@"username"]) {
        editor.serverNick.text = options[@"username"];
    }
    if (options[@"password"]) {
        editor.serverPassword.text = options[@"password"];
    }
    if (options[@"port"]) {
        editor.serverPort.text = options[@"port"];
    }
    if (options[@"hostname"]) {
        editor.serverHostname.text = options[@"hostname"];
        editor.serverName.placeholder = options[@"hostname"];
    }
    if (options[@"ssl"]) {
        editor.serverSSL.on = [options[@"ssl"] boolValue];
    }
    
    __weak RBServerViewController *theSelf = self;
    __weak RBServerEditorViewController *theEditor = editor;
    editor.onCancel = ^{
        if (!theEditor.server.nick.hasContent) {
            [theSelf.servers removeObject:theEditor.server];
        }
        [theSelf.tableView reloadData];
        [theSelf saveServerData];
    };
    return editor;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *currentText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([currentText hasPrefix:@"&"] || [currentText hasPrefix:@"#"]) {
        textField.textColor = [UIColor blackColor];
    } else {
        textField.textColor = [UIColor redColor];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text == nil || [textField.text isEqualToString:@""])
        return YES;
    if (!([textField.text hasPrefix:@"&"] || [textField.text hasPrefix:@"#"])) {
        return NO;
    }
    for (UITableViewCell *c in self.tableView.visibleCells) {
        if (![c isKindOfClass:[RBTextFieldServerCell class]])
            continue;
        RBTextFieldServerCell *cell = (RBTextFieldServerCell*)c;
        UITextField *tf = [cell textField];
        if ([tf.text isEqualToString:textField.text]) {
            RBIRCServer *server = cell.data;
            NSString *str = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [server join:str];
            [[NSNotificationCenter defaultCenter] postNotificationName:RBServerViewDidChangeChannel object:@{@"server": server, @"channel": server[str]}];            
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

-(void)IRCServer:(RBIRCServer *)server errorReadingFromStream:(NSError *)error
{
    NSString *title = NSLocalizedString(@"Error connecting to server", nil);
    NSString *message = [NSString localizedStringWithFormat:NSLocalizedString(@"Error connecting to %@, will reconnect", nil), server.hostname];
    self.av = [[UIAlertView alloc] initWithTitle:title message:message delegate:Nil cancelButtonTitle:@"Accept" otherButtonTitles:nil];
    [self.av show];
}

-(void)IRCServerConnectionDidDisconnect:(RBIRCServer *)server
{
    [self.tableView reloadData];
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
