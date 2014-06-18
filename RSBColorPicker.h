//
//  RSBColorPicker.h
//  Apartment
//
//  Created by Rachel Brindle on 6/8/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    RSBColorPickerStyleRGB,
    RSBColorPickerStyleRGBA,
    RSBColorPickerStyleGrayScale,
} RSBColorPickerStyle;

@interface RSBColorPicker : UIControl

// Defaults to RSBColorPickerStyleRGB
@property (nonatomic) RSBColorPickerStyle colorStyle;
@property (nonatomic, weak) UIColor *color;

@end
