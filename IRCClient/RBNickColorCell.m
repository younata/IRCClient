//
//  RBNickColorCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 6/17/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBNickColorCell.h"

#import "Nick.h"

#import "RSBColorPicker.h"

@interface RBNickColorCell ()

@property (nonatomic, strong) RSBColorPicker *colorPicker;

@end

@implementation RBNickColorCell

- (void)configureCell
{
    UILabel *label = [[UILabel alloc] initForAutoLayout];
    [self.contentView addSubview:label];
    [label autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 0) excludingEdge:ALEdgeBottom];
    [label autoSetDimension:ALDimensionHeight toSize:30];
    label.text = self.nick.name;
    label.textColor = self.nick.color;
    
    self.colorPicker = [[RSBColorPicker alloc] initForAutoLayout];
    self.colorPicker.color = self.nick.color;
    [self.contentView addSubview:self.colorPicker];
    self.colorPicker.hidden = YES;
    [self.colorPicker addTarget:self action:@selector(colorPicked) forControlEvents:UIControlEventValueChanged];
    
    [self.colorPicker autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.colorPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:label withOffset:10];
}

- (void)colorPicked
{
    self.nick.color = self.colorPicker.color;
    [self.nick.managedObjectContext save:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    [UIView animateWithDuration:0.2 animations:^{} completion:^(BOOL finished){
        self.colorPicker.hidden = !selected;
    }];
}

@end
