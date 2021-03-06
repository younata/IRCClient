//
//  RBServerViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <Blindside/Blindside.h>

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

#import "RBDataManager.h"

@interface RBServerViewController ()
{
    RBIRCChannel *selectedChannel;
}

@property (nonatomic, strong) UIAlertView *av;
@property (nonatomic, strong) id<BSInjector> injector;
@property (nonatomic, strong) RBDataManager *dataManager;

@end

static NSString *tableCell = @"tableViewCell";
static NSString *serverCell = @"serverCell";
static NSString *textFieldCell = @"textFieldCell";

@implementation RBServerViewController

+ (BSInitializer *)bsInitializer
{
    return [BSInitializer initializerWithClass:self selector:@selector(initWithDataManager:) argumentKeys:[RBDataManager class], nil];
}

- (instancetype)initWithDataManager:(RBDataManager *)dataManager
{
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.servers = [[NSMutableArray alloc] init];
        self.dataManager = dataManager;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Servers";
    
    self.navigationController.navigationBar.tintColor = [RBColorScheme secondaryColor];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:tableCell];
    [self.tableView registerClass:[RBServerCell class] forCellReuseIdentifier:serverCell];
    [self.tableView registerClass:[RBTextFieldServerCell class] forCellReuseIdentifier:textFieldCell];
        
    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
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
        if (![server connected] && [server.nick hasContent]) {
            [server reconnect];
        }
    }
}

-(void)saveServerData
{
    for (RBIRCServer *server in self.servers) {
        [self.dataManager serverMatchingIRCServer:server];
    }
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
    } else if (server != nil && row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:serverCell forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:tableCell forIndexPath:indexPath];
    }
    
    if (!server) {
        cell.textLabel.text = [@"+ " stringByAppendingString:NSLocalizedString(@"New Server", nil)];
        cell.textLabel.textColor = [RBColorScheme primaryColor];
    } else {
        cell.textLabel.textColor = server.connected ? [UIColor darkTextColor] : [[UIColor darkTextColor] colorWithAlphaComponent:0.5];
        if (row == channels.count) {
            RBTextFieldServerCell *c = (RBTextFieldServerCell *)cell;
            c.textField.placeholder = NSLocalizedString(@"Join a channel", nil);
            c.data = server;
            c.textField.delegate = self;
            [c layoutSubviews];
            cell = c;
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
            } else if ([server[channels[row]] isChannel]) {
                cell.textLabel.textColor = [RBColorScheme secondaryColor];
            } else {
                cell.textLabel.textColor = [RBColorScheme tertiaryColor];
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
    if (indexPath.row == 0)
        return disconnect;
    NSString *part = NSLocalizedString(@"Part", nil);
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
        Server *theServer = [self.dataManager serverMatchingIRCServer:server];
        [[theServer managedObjectContext] deleteObject:theServer];
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
        RBIRCServer *newServer = [self.injector getInstance:[RBIRCServer class]];
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
    RBServerEditorViewController *editor = [[RBServerEditorViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [editor view];
    
    RBIRCServer *server = options[@"server"];
    if (!server) {
        server = [self.injector getInstance:[RBIRCServer class]];
    }
    [editor setServer:server];

    if (![self.servers containsObject:server]) {
        [self.servers addObject:server];
    }
    if (options[@"username"]) {
        editor.nick = options[@"username"];
    }
    if (options[@"password"]) {
        editor.password = options[@"password"];
    }
    if (options[@"port"]) {
        editor.port = options[@"port"];
    }
    if (options[@"hostname"]) {
        editor.hostname = options[@"hostname"];
        editor.name = options[@"hostname"];
    }
    if (options[@"ssl"]) {
        editor.ssl = [options[@"ssl"] boolValue];
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
