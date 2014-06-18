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
@property (nonatomic, strong) NSMutableDictionary *nicks; // serverName: [names]

@end

@implementation RBNickColorPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.servers = [[[RBDataManager sharedInstance] servers] mutableCopy];
    
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    
    for (Server *server in self.servers) {
        if (server.nicks.count == 0 || server.name == nil) {
            [toRemove addObject:server];
        }
    }
    for (Server *server in toRemove) {
        [self.servers removeObject:server];
    }
    
    self.nicks = [[NSMutableDictionary alloc] init];
    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.servers[section] name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *serverName = [self.servers[section] name];
    if (!serverName) {
        return 0;
    }
    NSSet *nickSet = [self.servers[section] nicks];
    
    NSArray *nickArray = [[nickSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(Nick *a, Nick *b){
        return [a.name compare:b.name];
    }];
    
    self.nicks[serverName] = nickArray;
    
    return nickArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RBNickColorCell *cell = (RBNickColorCell *)[tableView dequeueReusableCellWithIdentifier:@"colorCell"];
    if (!cell) {
        cell = [[RBNickColorCell alloc] init];
    }
    
    NSString *serverName = [self.servers[indexPath.section] name];
    NSArray *nickArray = self.nicks[serverName];
    
    cell.nick = nickArray[indexPath.row];
    
    [cell configureCell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView indexPathsForSelectedRows] containsObject:indexPath]) {
        return 160;
    }
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];
    [tableView endUpdates];
}

@end
