//
//  RBConfigViewController.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/9/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBConfigViewController.h"

#import "RBReconnectViewController.h"

#import "UIButton+buttonWithFrame.h"

@interface RBConfigViewController ()

@end

@implementation RBConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.title = @"Configure";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    
    CGFloat width = self.view.frame.size.width;
    
    self.reconnectButton = [UIButton systemButtonWithFrame:CGRectMake(0, 80, width, 40)];
    self.reconnectButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.reconnectButton setTitle:@"Connect on Startup" forState:UIControlStateNormal];
    [self.reconnectButton addTarget:self action:@selector(pushReconnect) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.reconnectButton];
}

-(void)dismiss
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)save
{
    [self dismiss];
}

-(void)pushReconnect
{
    RBReconnectViewController *rvc = [[RBReconnectViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:rvc animated:YES];
}

@end
