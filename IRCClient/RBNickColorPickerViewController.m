//
//  RBNickColorPickerViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 6/17/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBNickColorPickerViewController.h"

#import "RBDataManager.h"

#import "RBNickColorCell.h"

@interface RBNickColorPickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation RBNickColorPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.servers = [[[RBDataManager sharedInstance] servers] mutableCopy];
    
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    
    for (Server *server in self.servers) {
        if (server.nicks.count == 0) {
            [toRemove addObject:server];
        }
    }
    for (Server *server in toRemove) {
        [self.servers removeObject:server];
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = YES;
    
    [self.tableView registerClass:[RBNickColorCell class] forCellReuseIdentifier:@"colorCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.servers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.servers[section] nicks] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RBNickColorCell *cell = (RBNickColorCell *)[tableView dequeueReusableCellWithIdentifier:@"colorCell"];
    if (!cell) {
        cell = [[RBNickColorCell alloc] init];
    }
    
    cell.nick = [[[self.servers[indexPath.section] nicks] allObjects] objectAtIndex:indexPath.row];
    
    [cell configureCell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView indexPathsForSelectedRows] containsObject:indexPath]) {
        return 80;
    }
    return 40;
}

@end
