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
NSString *const kBackgroundOperationQueue = @"kBackgroundOperationQueue";

@implementation ApplicationModule

- (void)configure:(id) binder {
    [binder bind:kMainOperationQueue toInstance:[NSOperationQueue mainQueue]];

    NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
    backgroundQueue.underlyingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [binder bind:kBackgroundOperationQueue toInstance:backgroundQueue];
}

@end
