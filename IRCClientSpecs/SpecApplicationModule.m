//
//  SpecApplicationModule.m
//  IRCClient
//
//  Created by Rachel Brindle on 3/29/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

#import "SpecApplicationModule.h"

#import <Fakes/FakeOperationQueue.h>

@implementation SpecApplicationModule

- (void)configure:(id<BSBinder>)binder
{
    [super configure:binder];

    FakeOperationQueue *fakeMainQueue = [[FakeOperationQueue alloc] init];
    [binder bind:kMainOperationQueue toInstance:fakeMainQueue];

    FakeOperationQueue *fakeBackgroundQueue = [[FakeOperationQueue alloc] init];
    [binder bind:kBackgroundOperationQueue toInstance:fakeBackgroundQueue];
}

@end
