//
//  RBConfigViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/9/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBConfigViewController.h"

#import "RBReconnectViewController.h"

#import "UIButton+buttonWithFrame.h"

#import "SWRevealViewController.h"
#import "RBServerViewController.h"

#import "RBColorScheme.h"

#import "RBScriptingService.h"

static NSString *CellIdentifier = @"Cell";
static NSString *textFieldCell = @"textFieldCell";

@interface RBConfigViewController ()
@property (nonatomic, strong) NSMutableDictionary *values;

@end

@implementation RBConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    [[RBScriptingService sharedInstance] runEnabledScripts];
    
    self.navigationItem.title = NSLocalizedString(@"Configure", nil);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    
    self.navigationController.navigationBar.tintColor = [RBColorScheme primaryColor];
    
    self.values = [[NSMutableDictionary alloc] init];
    for (NSString *key in [[RBScriptingService sharedInstance] scripts]) {
        NSNumber *val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (val == nil) {
            val = @(NO);
            [[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
        }
        [self.values setObject:val forKey:key];
    }
}

-(void)dismiss
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)save
{
    for (NSString *key in self.values.allKeys) {
        [[NSUserDefaults standardUserDefaults] setObject:self.values[key] forKey:key];
    }
    
    [[RBScriptingService sharedInstance] runEnabledScripts];
    [self dismiss];
}

-(void)pushReconnect
{
    RBReconnectViewController *rvc = [[RBReconnectViewController alloc] initWithStyle:UITableViewStyleGrouped];
    SWRevealViewController *vc = (SWRevealViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    rvc.servers = [(RBServerViewController *)[(UINavigationController *)[vc rearViewController] topViewController] servers];
    [self.navigationController pushViewController:rvc animated:YES];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3; // reconnect, ctcp, scripts
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: // reconnect
            return 1;
        case 1: // ctcp, 2 (finger and clientinfo)
            return 2;
        case 2:
            return [[[RBScriptingService sharedInstance] scripts] count];
        default:
            return 0;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 1:
            return NSLocalizedString(@"CTCP Responses", nil);
        case 2:
            return NSLocalizedString(@"Extensions", nil);
        default:
            return @"";
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.textColor = [RBColorScheme primaryColor];
    
    if (section == 0) { // reconnect
        cell.textLabel.text = NSLocalizedString(@"Connect on Startup", nil);
    } else if (section == 1) { // ctcp
        NSArray *rawStrings = @[@"Finger", @"UserInfo"];
        NSArray *strings = @[NSLocalizedString(@"Finger", nil), NSLocalizedString(@"UserInfo", nil)];
        cell.textLabel.text = strings[row];
        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectZero];
        tf.text = [[NSUserDefaults standardUserDefaults] objectForKey:rawStrings[row]];
        tf.placeholder = @"response";
        
        cell.accessoryView = tf;
        [cell layoutSubviews];
    } else if (section == 2) { // scripts
        cell.textLabel.textColor = [RBColorScheme secondaryColor];
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = s;
        NSString *key = self.values.allKeys[row];
        s.on = [self.values[key] boolValue];
        [s addTarget:self action:@selector(setScript:) forControlEvents:UIControlEventValueChanged];
        
        cell.textLabel.text = key;
    }
    
    return cell;
}

-(void)setScript:(UISwitch *)theSwitch
{
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        if ([cell.subviews containsObject:theSwitch]) {
            [self.values setObject:@(theSwitch.on) forKey:cell.textLabel.text];
        }
    }
}


@end
