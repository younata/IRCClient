//
//  RBKeyboardViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 3/12/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBKeyboardViewController.h"
#import "NSObject+customProperty.h"

@interface RBKeyboardViewController ()

@end

static NSString *cellIdentifier = @"Cell";

@implementation RBKeyboardViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
}

-(void)save
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Chorded Keyboard - QWERTY-based", nil);
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Chorded Keyboard - Dvorak-based", nil);
            break;
        default:
            break;
    }
    
    UISwitch *sw = [[UISwitch alloc] init];
    [sw addTarget:self action:@selector(changeKeyboard:) forControlEvents:UIControlEventValueChanged];
    [sw setCustomProperty:cell forKey:@"key"];
    [cell setAccessoryView:sw];
    
    return cell;
}

-(void)changeKeyboard:(UISwitch *)sw
{
    UITableViewCell *cell = [sw getCustomPropertyForKey:@"key"];
    
    NSIndexPath *ip = [self.tableView indexPathForCell:cell];
    
    if (sw.on) {
        for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++) {
            for (NSInteger row = 0; row < [self tableView:self.tableView numberOfRowsInSection:section]; row++) {
                if (section == ip.section && row == ip.row) {
                    continue;
                }
                UITableViewCell *theCell = [self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                UISwitch *s = (UISwitch *)[theCell accessoryView];
                [s setOn:NO];
            }
        }
    }
}

@end
