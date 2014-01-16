//
//  RBChannelViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/15/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBIRCChannel;

@interface RBChannelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    UITextField *input;
    UITableView *tableView;
}

@property (nonatomic, weak) RBIRCChannel *channel;

@end
