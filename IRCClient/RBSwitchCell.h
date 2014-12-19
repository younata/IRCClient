//
//  RBSwitchCell.h
//  IRCClient
//
//  Created by Rachel Brindle on 12/18/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBSwitchCell : UITableViewCell

@property (nonatomic, strong) UISwitch *theSwitch;

@property (nonatomic, strong) void (^onSwitchChange)(BOOL);

@end
