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

@interface RBServerViewController ()

@end

static NSString *CellIdentifier = @"Cell";

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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.servers count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section > [self.servers count]) {
        return 1;
    }
    RBIRCServer *server = self.servers[section];
    return [server.channels count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section > [self.servers count]) {
        cell.textLabel.text = @"New Server";
    } else {
        RBIRCServer *server = self.servers[section];
        NSArray *channels = [server.channels allKeys];
        if (row != 0) {
            cell.textLabel.text = channels[row - 1];
        } else {
            cell.textLabel.text = server.serverName;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.servers[section] serverName];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section != self.servers.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section > [self.servers count]) {
        RBIRCServer *server = self.servers[section];
        NSArray *channels = [server.channels allKeys];
        NSString *ch = channels[row];
        RBIRCChannel *channel = server[ch];
        
        [self.delegate server:server didChangeChannel:channel];
    } else {
        // bring up a new server dialog.
    }
}

@end
