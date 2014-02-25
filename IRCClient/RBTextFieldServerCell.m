//
//  RBTextFieldServerCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBTextFieldServerCell.h"

@implementation RBTextFieldServerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.textField = [[UITextField alloc] initForAutoLayoutWithSuperview:self.contentView];
        [self.textField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, self.indentationLevel * self.indentationWidth, 0, 0)];
        [self.contentView addSubview:self.textField];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TextFieldServerCell with data '%@' and textfield '%@'", self.data, self.textField];
}

@end
