//
//  RBChordedKeyboardDvorak.h
//
//  Created by Rachel Brindle on 11/9/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBChordedKeyboardDelegate.h"

@interface RBChordedKeyboardDvorak : NSObject <RBChordedKeyboardDelegate>
{
    NSArray *keyMap;
}

@end

/*
 b -> x
 v -> y
 u -> b
 q -> j
 x -> q
 q -> j
 y -> u
*/