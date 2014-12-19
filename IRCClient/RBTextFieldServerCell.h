//
//  RBTextFieldServerCell.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBTextFieldServerCell : UITableViewCell

@property (nonatomic, weak) id data;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) void (^onTextChange)(NSString *);

@end
