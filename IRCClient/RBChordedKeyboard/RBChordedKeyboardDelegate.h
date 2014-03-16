//
//  RBChordedKeyboardDelegate.h
//
//  Created by Rachel Brindle on 11/9/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RBChordedKeyboardDelegate <NSObject>

-(NSArray *)keyMappings; // basically, an array of size 256...
-(NSString *)keySequenceWasPressed:(int)keys;

@end
