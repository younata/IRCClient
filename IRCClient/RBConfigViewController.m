//
//  RBConfigViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/9/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBConfigViewController.h"

#import "RBConfigurationKeys.h"
#import "RBNickColorPickerViewController.h"
#import "RBKeyboardViewController.h"

#import "UIButton+buttonWithFrame.h"

#import "SWRevealViewController.h"
#import "RBChannelViewController.h"
#import "RBServerViewController.h"

#import "RBColorScheme.h"

#import "RBScriptingService.h"

#import "NSObject+customProperty.h"

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
    
    SWRevealViewController *rvc = (SWRevealViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    RBServerViewController *svc = (RBServerViewController *)[(UINavigationController *)[rvc rearViewController] topViewController];
    RBChannelViewController *cvc = (RBChannelViewController *)[(UINavigationController *)[rvc frontViewController] topViewController];
    [svc.tableView reloadData];
    [cvc.tableView reloadData];
    
    
    [self dismiss];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;//5; // reconnect, ctcp, scripts, images, experimental (disabled)
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: // nick colors
            return 1;
        case 1: // ctcp, 2 (finger and clientinfo)
            return 2;
        case 2:
            return [[[RBScriptingService sharedInstance] scripts] count];
        case 3:
            return 2; // display inline, display nsfw
        case 4:
            return 1;
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
        case 3:
            return NSLocalizedString(@"Inline Images", nil);
        case 4:
            return NSLocalizedString(@"Experimental", nil);
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
    
    if (section == 0) { // reconnect
        cell.textLabel.textColor = [RBColorScheme secondaryColor];
        cell.textLabel.text = NSLocalizedString(@"Nick Colors", nil);
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
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = s;
        NSString *key = self.values.allKeys[row];
        s.on = [self.values[key] boolValue];
        [s addTarget:self action:@selector(setScript:) forControlEvents:UIControlEventValueChanged];
        [s setCustomProperty:key forKey:@"scriptKey"];
        
        cell.textLabel.text = key;
    } else if (section == 3) {
        NSArray *strings = @[NSLocalizedString(@"Display images inline", nil),
                             NSLocalizedString(@"Display NSFW images", nil)];
        cell.textLabel.text = strings[row];
        
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectZero];
        NSString *key;
        switch (row) {
            case 0:
                key = RBConfigLoadImages;
                break;
            case 1:
                key = RBConfigDontLoadNSFW;
                break;
            default:
                break;
        }
        s.on = [[NSUserDefaults standardUserDefaults] boolForKey:key];
        self.values[key] = @(s.on);
        [s addTarget:self action:@selector(setScript:) forControlEvents:UIControlEventValueChanged];
        [s setCustomProperty:key forKey:@"scriptKey"];
        cell.accessoryView = s;
    } else if (section == 4) {
        NSArray *strings = @[NSLocalizedString(@"Keyboards", nil)];
        cell.textLabel.text = strings[row];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        } else {
            cell.textLabel.textColor = [RBColorScheme secondaryColor];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == 0) {
        RBNickColorPickerViewController *rncpvc = [[RBNickColorPickerViewController alloc] init];
        [self.navigationController pushViewController:rncpvc animated:YES];
    } else if (section == 4) {
        NSInteger row = indexPath.row;
        switch (row) {
            case 0:
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    RBKeyboardViewController *kvc = [[RBKeyboardViewController alloc] init];
                    [self.navigationController pushViewController:kvc animated:YES];
                }
                break;
            default:
                break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)setScript:(UISwitch *)theSwitch
{
    NSString *key = [theSwitch getCustomPropertyForKey:@"scriptKey"];
    if (key) {
        [self.values setObject:@(theSwitch.on) forKey:key];
    }
}


@end
