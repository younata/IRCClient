//
//  RBKeyboardViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 3/12/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBKeyboardViewController.h"
#import "NSObject+customProperty.h"

#import "RBConfigurationKeys.h"

#import "RBChordedKeyboard.h"
#import "RBChordedKeyboardQwerty.h"
#import "RBChordedKeyboardDvorak.h"

@interface RBKeyboardViewController ()
{
    NSString *chordedQwerty, *chordedDvorak;
    NSString *def;
    
    NSMutableDictionary *keyboards;
}

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
    
    chordedQwerty = NSLocalizedString(@"Chorded Keyboard - QWERTY-based", nil);
    chordedDvorak = NSLocalizedString(@"Chorded Keyboard - Dvorak-based", nil);
    def = NSLocalizedString(@"Default Keyboard", nil);
    
    keyboards = [[NSMutableDictionary alloc] initWithDictionary:@{chordedQwerty: @(NO), chordedDvorak: @(NO), def: @(YES)}];
    Class cls = [[NSUserDefaults standardUserDefaults] objectForKey:RBConfigKeyboard];
    if (cls != nil) {
        if ([NSStringFromClass(cls) isEqualToString:NSStringFromClass([RBChordedKeyboardQwerty class])]) {
            keyboards[chordedQwerty] = @(YES);
            keyboards[def] = @(NO);
        } else {
            keyboards[chordedDvorak] = @(YES);
            keyboards[def] = @(NO);
        }
    }
}

-(void)save
{
    if (keyboards[chordedQwerty]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RBChordedKeyboardQwerty class] forKey:RBConfigKeyboard];
    } else if (keyboards[chordedDvorak]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RBChordedKeyboardDvorak class] forKey:RBConfigKeyboard];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RBConfigKeyboard];
    }
    // of course, this isn't actually worth anything if all of the views ignore it...
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = chordedQwerty;
                break;
            case 1:
                cell.textLabel.text = chordedDvorak;
                break;
            default:
                break;
        }
    } else {
        cell.textLabel.text = def;
    }
    
    UISwitch *sw = [[UISwitch alloc] init];
    [sw addTarget:self action:@selector(changeKeyboard:) forControlEvents:UIControlEventValueChanged];
    [sw setCustomProperty:cell forKey:@"key"];
    sw.on = [keyboards[cell.textLabel.text] boolValue];
    [cell setAccessoryView:sw];
    
    return cell;
}

-(void)changeKeyboard:(UISwitch *)sw
{
    UITableViewCell *cell = [sw getCustomPropertyForKey:@"key"];
    
    NSIndexPath *ip = [self.tableView indexPathForCell:cell];
    
    if (sw.on) {
        for (UITableViewCell *otherCell in self.tableView.visibleCells) {
            if ([[self.tableView indexPathForCell:otherCell] isEqual:ip]) {
                UISwitch *s = (UISwitch *)[otherCell accessoryView];
                [s setOn:NO];
            }
        }
        for (NSString *key in keyboards.allKeys) {
            keyboards[key] = @([key isEqualToString:cell.textLabel.text]);
        }
    }
}

@end
