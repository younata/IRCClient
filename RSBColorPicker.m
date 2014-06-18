//
//  RSBColorPicker.m
//  Apartment
//
//  Created by Rachel Brindle on 6/8/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RSBColorPicker.h"
#import "AHKSlider.h"

@interface RSBColorPicker ()

@property (nonatomic, strong) AHKSlider *redSlider;
@property (nonatomic, strong) AHKSlider *greenSlider;
@property (nonatomic, strong) AHKSlider *blueSlider;

@property (nonatomic, strong) AHKSlider *alphaSlider;

@property (nonatomic, strong) AHKSlider *graySlider;

@property (nonatomic, strong) UIView *preview;

@end

@implementation RSBColorPicker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preview = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.preview];
        [self.preview autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.preview autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.preview autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
        [self.preview autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.25];
        
        self.redSlider = [[AHKSlider alloc] initForAutoLayout];
        [self addSubview:self.redSlider];
        
        self.greenSlider = [[AHKSlider alloc] initForAutoLayout];
        [self addSubview:self.greenSlider];
        
        self.blueSlider = [[AHKSlider alloc] initForAutoLayout];
        [self addSubview:self.blueSlider];
        
        self.alphaSlider = [[AHKSlider alloc] initForAutoLayout];
        [self addSubview:self.alphaSlider];
        
        self.graySlider = [[AHKSlider alloc] initForAutoLayout];
        [self addSubview:self.graySlider];
        
        for (UISlider *slider in @[self.redSlider, self.greenSlider, self.blueSlider, self.alphaSlider, self.graySlider]) {
            slider.maximumValue = 1.0;
            slider.minimumValue = 0.0;
            [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        self.colorStyle = RSBColorPickerStyleRGB;
        self.bounds = CGRectMake(0, 0, 120, 30);
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    if ([target respondsToSelector:action]) {
        NSMethodSignature *sig = [target methodSignatureForSelector:action];
        if (sig.numberOfArguments == 1) {
            [target performSelector:action withObject:self];
        } else if (sig.numberOfArguments == 0) {
            [target performSelector:action];
        }
    }
}

- (void)sliderChanged:(UISlider *)slider
{
    self.preview.backgroundColor = self.color;
}

- (void)setColor:(UIColor *)color
{
    CGFloat red, green, blue, alpha = 1.0;
    CGFloat gray;
    switch (self.colorStyle) {
        case RSBColorPickerStyleRGBA:
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            self.redSlider.value = red;
            self.greenSlider.value = green;
            self.blueSlider.value = blue;
            self.alphaSlider.value = alpha;
            break;
        case RSBColorPickerStyleRGB:
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            self.redSlider.value = red;
            self.greenSlider.value = green;
            self.blueSlider.value = blue;
            break;
        case RSBColorPickerStyleGrayScale:
            [color getWhite:&gray alpha:&alpha];
            self.graySlider.value = gray;
            break;
    }
    [self sliderChanged:nil];
}

- (UIColor *)color
{
    CGFloat red, green, blue, alpha = 1.0;
    switch (self.colorStyle) {
        case RSBColorPickerStyleRGBA:
            alpha = self.alphaSlider.value;
        case RSBColorPickerStyleRGB:
            red = self.redSlider.value;
            green = self.greenSlider.value;
            blue = self.blueSlider.value;
            break;
        case RSBColorPickerStyleGrayScale:
            red = green = blue = self.graySlider.value;
            break;
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)setColorStyle:(RSBColorPickerStyle)colorStyle
{
    _colorStyle = colorStyle;
    for (UIView *v in @[self.redSlider, self.greenSlider, self.blueSlider, self.alphaSlider, self.graySlider]) {
        [v removeConstraints:v.constraints];
        v.hidden = YES;
    }
    
    switch (colorStyle) {
        case RSBColorPickerStyleRGB: {
            NSArray *sliders = @[self.redSlider, self.greenSlider, self.blueSlider];
            [sliders autoDistributeViewsAlongAxis:ALAxisVertical withFixedSize:20 alignment:NSLayoutFormatAlignAllLeft];
            for (UIView *v in sliders) {
                [v autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
                [v autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.preview withOffset:8];
                v.hidden = NO;
            }
            break;
        } case RSBColorPickerStyleRGBA: {
            NSArray *sliders = @[self.redSlider, self.greenSlider, self.blueSlider, self.alphaSlider];
            [sliders autoDistributeViewsAlongAxis:ALAxisVertical withFixedSize:20 alignment:NSLayoutFormatAlignAllLeft];
            for (UIView *v in sliders) {
                [v autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
                [v autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.preview withOffset:8];
                v.hidden = NO;
            }
            break;
        } case RSBColorPickerStyleGrayScale: {
            UIView *v = self.graySlider;
            [v autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.preview];
            [v autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
            [v autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.preview withOffset:8];
            v.hidden = NO;
            break;
        }
    }
}

@end
