//
//  ApplicationModule.m
//  IRCClient
//
//  Created by Rachel Brindle on 3/29/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

#import <Blindside/Blindside.h>
#import "ApplicationModule.h"

NSString *const kMainOperationQueue = @"kMainOperationQueue";

@implementation ApplicationModule

- (void)configure:(id) binder {
    [binder bind:kMainOperationQueue toInstance:[NSOperationQueue mainQueue]];
}

@end
