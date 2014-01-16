//
//  RBBackViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBBackViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *tv;
}

@property (nonatomic, strong) NSMutableArray *servers;

@end
