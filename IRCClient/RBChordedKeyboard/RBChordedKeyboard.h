//
//  RBChordedKeyboard.h
//
//  Created by Rachel Brindle on 11/8/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBChordedKeyboardDelegate.h"

@interface RBChordedKeyboard : UIView
{
    UIView *l1, *l2, *l3, *l4, *r4, *r3, *r2, *r1;
    UIView *shift, *space;
    NSMutableArray *currentKeyStroke;
    int currentKeys;
    NSArray *allKeys;
}

@property (nonatomic, strong) NSObject <RBChordedKeyboardDelegate> *delegate;
@property (nonatomic, weak) id <UITextInput> textView;

@end
