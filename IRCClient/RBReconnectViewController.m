//
//  RBReconnectViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/8/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBReconnectViewController.h"

@interface RBReconnectViewController ()

@end

static NSString *CellIdentifier = @"Cell";

@implementation RBReconnectViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.servers = @{};
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
    return [self.servers.allKeys count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.servers.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
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

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
