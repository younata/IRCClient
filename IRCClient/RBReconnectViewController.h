//
//  RBReconnectViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 2/8/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBReconnectViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *servers;

-(void)save;

@end
