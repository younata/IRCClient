//
//  RBSwitchCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 12/18/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBSwitchCell.h"

@implementation RBSwitchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.theSwitch = [[UISwitch alloc] initForAutoLayoutWithSuperview:self.contentView];
        [self.theSwitch autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 1 * self.indentationWidth) excludingEdge:ALEdgeLeft];
        
        [self.theSwitch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)switchChanged
{
    self.onSwitchChange(self.theSwitch.on);
}

@end
