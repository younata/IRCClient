//
//  RBServerViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RBServerVCDelegate;

@interface RBServerViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, weak) id<RBServerVCDelegate> delegate;

@end
