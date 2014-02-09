//
//  RBConfigViewController.h
//  IRCClient
//
//  Created by Rachel Brindle on 2/9/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBConfigViewController : UIViewController

@property (nonatomic, strong) UIButton *reconnectButton;

-(void)dismiss;
-(void)save;

@end
