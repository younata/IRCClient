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

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) RSBColorPicker *colorPicker;

@end

@implementation RBNickColorCell

- (void)configureCell
{
    if (self.label) {
        [self.label removeFromSuperview];
    }
    self.label = [[UILabel alloc] initForAutoLayout];
    [self.contentView addSubview:self.label];
    [self.label autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 0) excludingEdge:ALEdgeBottom];
    [self.label autoSetDimension:ALDimensionHeight toSize:30];
    self.label.text = self.nick.name;
    self.label.textColor = self.nick.color;
    
    self.colorPicker = [[RSBColorPicker alloc] initForAutoLayout];
    self.colorPicker.color = self.nick.color;
    [self.contentView addSubview:self.colorPicker];
    self.colorPicker.hidden = YES;
    [self.colorPicker addTarget:self action:@selector(colorPicked) forControlEvents:UIControlEventValueChanged];
    
    [self.colorPicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.colorPicker autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.colorPicker autoSetDimension:ALDimensionHeight toSize:120];
    [self.colorPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.label withOffset:10];
}

- (void)colorPicked
{
    self.nick.color = self.colorPicker.color;
    self.label.textColor = self.colorPicker.color;
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
