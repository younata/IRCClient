//
//  RBNameViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 3/11/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBNameViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *names;
@property (nonatomic, copy) NSString *topic;
@property (nonatomic, copy) NSString *serverName;

@end
