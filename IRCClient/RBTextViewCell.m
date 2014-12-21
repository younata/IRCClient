//
//  RBTextViewCell.m
//  IRCClient
//
//  Created by Rachel Brindle on 4/29/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBTextViewCell.h"

@implementation RBTextViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textView = [[UITextView alloc] initForAutoLayoutWithSuperview:self.contentView];
        [self.textView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        self.textView.dataDetectorTypes = UIDataDetectorTypeLink;
        self.textView.editable = NO;
        self.textView.userInteractionEnabled = YES;
        self.textView.scrollEnabled = NO;
        self.textView.textContainerInset = UIEdgeInsetsMake(5, 5, 0, 0);
    }
    return self;
}

@end
