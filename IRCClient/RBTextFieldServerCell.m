//
//  RBTextFieldServerCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBTextFieldServerCell.h"
#import "UIView+initWithSuperview.h"

@implementation RBTextFieldServerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.textField = [[UITextField alloc] initForAutoLayoutWithSuperview:self.contentView];
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self.textField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 1 * self.indentationWidth, 0, 0)];
        [self.contentView addSubview:self.textField];
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"TextFieldServerCell with data '%@' and textfield '%@'", self.data, self.textField];
}

@end
