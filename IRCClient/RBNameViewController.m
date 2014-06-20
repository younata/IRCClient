#import "RBNameViewController.h"

#import "RBDataManager.h"

#import "Nick.h"
#import "Server.h"

@interface RBNameViewController ()

@property (nonatomic, strong) Server *server;

@end

static NSString *CellIdentifier = @"Cell";

@implementation RBNameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)setServerName:(NSString *)serverName
{
    _serverName = serverName.copy;
    
    self.server = [[RBDataManager sharedInstance] serverForServerName:serverName];
}

- (void)setNames:(NSMutableArray *)names
{
    _names = names;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.names.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = self.names[indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    
    // valid nick prefixes: @"~", @"&", @"@", @"%", @"+"
    NSString *nickName = [cell.textLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+%@&~"]];
    
    Nick *nick = [[RBDataManager sharedInstance] nick:nickName onServer:self.server];
    if (nick) {
        cell.textLabel.textColor = nick.color;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
