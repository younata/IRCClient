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
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *path = [self.tableView indexPathForCell:cell];
        UISwitch *s = (UISwitch *)cell.accessoryView;
        RBIRCServer *server = self.servers[path.section];
        if (path.row == 0) {
            [server setConnectOnStartup:[s isOn]];
        } else {
            NSString *key = cell.textLabel.text;
            RBIRCChannel *channel = server.channels[key];
            [channel setConnectOnStartup:[s isOn]];
        }
    }
    d = [NSKeyedArchiver archivedDataWithRootObject:self.servers];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:RBConfigServers];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSArray *)sortChannelKeys:(NSArray *)channelKeys
{
    return [channelKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        NSString *a = (NSString *)obj1;
        NSString *b = (NSString *)obj2;
        
        if ([a isEqualToString:RBIRCServerLog])
            return NSOrderedAscending;
        else if ([b isEqualToString:RBIRCServerLog])
            return NSOrderedDescending;
        return [a compare:b];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.servers count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(RBIRCServer*)self.servers[section] channels].allKeys.count; // + 1 for servername, - 1 for server log
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    RBIRCServer *server = self.servers[section];
    NSArray *channelKeys = server.channels.allKeys;
    
    channelKeys = [self sortChannelKeys:channelKeys];
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = s;
    [cell layoutSubviews];
    if (row > 0) {
        cell.indentationLevel = 1;
        RBIRCChannel *channel = server.channels[channelKeys[row]];
        cell.textLabel.text = channel.name;
        s.on = channel.connectOnStartup;
    } else {
        cell.textLabel.text = server.serverName;
        s.on = server.connectOnStartup;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section != self.servers.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
