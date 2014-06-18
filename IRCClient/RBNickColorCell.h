//
//  RBNickColorCell.h
//  IRCClient
//
//  Created by Rachel Brindle on 6/17/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Nick;

@interface RBNickColorCell : UITableViewCell

@property (nonatomic, strong) Nick *nick;

- (void)configureCell;

@end
