//
//  RBReconnectViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/8/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBReconnectViewController.h"
#import "RBConfigurationKeys.h"
#import "RBIRCServer.h"
#import "RBIRCChannel.h"

@interface RBReconnectViewController ()
@property (nonatomic, strong) NSMutableDictionary *switches;

@end

static NSString *CellIdentifier = @"Cell";

@implementation RBReconnectViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.servers = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self reloadServerData];
    [self.tableView reloadData];
    
    self.navigationItem.title = NSLocalizedString(@"Connect on Startup", nil);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    self.switches = [[NSMutableDictionary alloc] init];
}

-(void)reloadServerData
{
    NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigServers];
    if (d == nil) {
        self.servers = @[];
    } else {
        self.servers = [NSKeyedUnarchiver unarchiveObjectWithData:d];
    }
}

-(void)save
{
    NSData *d;
    
    d = [NSKeyedArchiver archivedDataWithRootObject:self.servers];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(id)serverOrChannelForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBIRCServer *server = self.servers[section];
    NSMutableArray *channelKeys = [server.sortedChannelKeys mutableCopy];
    [channelKeys removeObject:RBIRCServerLog];
    if (row == 0) {
        return server;
    }
    
    return server[channelKeys[row]];
}

-(void)switchChange:(UISwitch *)sender
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isEqual:sender]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            [[self serverOrChannelForIndexPath:indexPath] setConnectOnStartup:sender.on];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.servers count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    RBIRCServer *server = self.servers[section];
    NSArray *channels = server.sortedChannelKeys;
    return channels.count - 1; // - 1 for serverlog
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBIRCServer *server = self.servers[section];
    NSMutableArray *channelKeys = [server.sortedChannelKeys mutableCopy];
    [channelKeys removeObject:RBIRCServerLog];
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = s;
    [cell layoutSubviews];
    s.on = row == 0 ? server.connectOnStartup : [server[channelKeys[row]] connectOnStartup];
    [s addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    
    cell.textLabel.text = channelKeys[row];
    
    if (row > 0) {
        cell.indentationLevel = 1;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section != self.servers.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UISwitch *s = (UISwitch *)[tableView cellForRowAtIndexPath:indexPath];
    s.on = ~s.on;
    id sc = [self serverOrChannelForIndexPath:indexPath];
    [sc setConnectOnStartup:s.on];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [tableView reloadData];
}

@end
