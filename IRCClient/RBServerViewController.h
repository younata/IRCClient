//
//  RBServerViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

@protocol RBServerVCDelegate;
@class RBServerEditorViewController;

@interface RBServerViewController : UITableViewController <UITextFieldDelegate, SWRevealViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, weak) id<RBServerVCDelegate> delegate;
@property (nonatomic, weak) SWRevealViewController *revealController;

-(RBServerEditorViewController *)editorViewControllerWithOptions:(NSDictionary *)options;

@end
