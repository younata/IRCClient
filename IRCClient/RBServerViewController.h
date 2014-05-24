//
//  RBServerViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 1/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

#define RBServerViewDidChangeChannel @"RBServerViewDidChangeChannel"
#define RBServerViewDidDisconnectServer @"RBServerViewDidDisconnectServer"
#define RBServerViewDidDisconnectChannel @"RBServerViewDidDisconnectChannel"

@class RBServerEditorViewController;

@interface RBServerViewController : UITableViewController <UITextFieldDelegate, SWRevealViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, weak) SWRevealViewController *revealController;

-(RBServerEditorViewController *)editorViewControllerWithOptions:(NSDictionary *)options;

-(void)handleNotification:(NSNotification *)note;

@end
