//
//  RBChordedKeyboard.m
//
//  Created by Rachel Brindle on 11/8/12.
//  Copyright (c) 2012 Rachel Brindle. All rights reserved.
//

#import "RBChordedKeyboard.h"
#import <QuartzCore/QuartzCore.h>

@implementation RBChordedKeyboard

- (id)initWithFrame:(CGRect)frame
{
    NSAssert([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad, @"Chorded keyboards do not work with the small screens of iPhones and iPod Touches!");
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];

    }
    return self;
}

-(id)init
{
    NSAssert([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad, @"Chorded keyboards do not work with the small screens of iPhones and iPod Touches!");
    CGRect f = CGRectMake(0, 296, 1024, 452);
    self = [super initWithFrame:f];
    if (self) {
        [self commonInit];
        
    }
    return self;
}

-(void)commonInit
{
    CGFloat y = 768 - 472;
    self.frame = CGRectMake(0, y, 1024, 452);
    self.backgroundColor = [UIColor whiteColor];
    
    [self setMultipleTouchEnabled:YES];
    
    CGFloat x = 0;
    y = 0;
    static CGFloat width=120, height=200;
    x = 6; y = 52;
    l1 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 132; y = 20;
    l2 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 260; y = 0;
    l3 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 386; y = 32;
    l4 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    
    x = 898; y = 52;
    r1 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 772; y = 20;
    r2 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 644; y = 0;
    r3 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    x = 518; y = 32;
    r4 = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        
    x = 306; y = 250;
    shift = [[UIView alloc] initWithFrame:CGRectMake(x, y, height, height)];
    x = 518;
    space = [[UIView alloc] initWithFrame:CGRectMake(x, y, height, height)];
    
    allKeys = @[l1,l2,l3,l4,r4,r3,r2,r1,shift,space];
    
    for (UIView *v in allKeys) {
        [v setBackgroundColor:[UIColor clearColor]];
        v.layer.borderColor = [UIColor lightGrayColor].CGColor;
        v.layer.borderWidth = 2;
        [self addSubview:v];
    }
    
    currentKeyStroke = [[NSMutableArray alloc] initWithCapacity:[allKeys count]];
    currentKeys = 0;
}

-(void)setDelegate:(NSObject<RBChordedKeyboardDelegate> *)delegate
{
    _delegate = delegate;
    NSArray *mapping = [_delegate keyMappings];
    NSAssert([mapping count] == 256, @"Error, RBChordedKeyboardDelegate:keyMappings MUST return an array of size 0x100");
    [self setKeyLabels:@[]];
}

-(void)setKeyLabels:(NSArray *)pressedKeys
{
    NSString *ret = [self currentKeyForKeystrokes:pressedKeys];
    for (NSInteger i = 0; i < 10; i++) {
        NSString *toAddStr = ret;
        UIView *v = [allKeys objectAtIndex:i];
        NSArray *a = [pressedKeys arrayByAddingObject:v];
        toAddStr = [self currentKeyForKeystrokes:a];
        
        if (i >= 8) {
            if ([toAddStr isEqualToString:@"\n"])
                toAddStr = @"Newline";
            else if ([toAddStr isEqualToString:@" "])
                toAddStr = @"Space";
            else if ([toAddStr isEqualToString:@""] && ([a containsObject:shift]))
                toAddStr = @"Shift";
        }
        NSString *nextStr = @"";
        if (i < 8) {
            for (NSInteger j = 0; j < 8; j++) {
                if (j == i)
                    continue;
                UIView *w = [allKeys objectAtIndex:j];
                if (j == 8 || (j == 7 && i == 8))
                    nextStr = [nextStr stringByAppendingString:[self currentKeyForKeystrokes:[a arrayByAddingObject:w]]];
                else
                    nextStr = [nextStr stringByAppendingFormat:@"%@ ", [self currentKeyForKeystrokes:[a arrayByAddingObject:w]]];
            }
        }
        if ([nextStr length] > 12)
            toAddStr = [toAddStr stringByAppendingFormat:@"\n%@", nextStr];
        BOOL hasLabelAsSubview = NO;
        for (UIView *sv in v.subviews) {
            if ([sv isMemberOfClass:[UILabel class]]) {
                hasLabelAsSubview = YES;
                [((UILabel *)sv) setText:toAddStr];
            }
        }
        if (!hasLabelAsSubview) {
            CGRect f = CGRectMake(0, 0, v.frame.size.width, 60);
            UILabel *l = [[UILabel alloc] initWithFrame:f];
            l.text = toAddStr;
            l.font = [UIFont systemFontOfSize:18];
            l.textAlignment = NSTextAlignmentCenter;
            l.backgroundColor = [UIColor clearColor];
            if (i >= 8)
                l.textColor = [UIColor grayColor];
            l.numberOfLines = 0;
            [v addSubview:l];
        }
    }
}

-(NSString *)convertNonAlphaNumericToShift:(NSString *)str
{
    if ([str length] == 0)
        return @"";
    unichar c = [str characterAtIndex:0];
    switch (c) {
        case '.':
            return @">";
        case ',':
            return @"<";
        case '(':
            return @"{";
        case ')':
            return @"}";
        case '?':
            return @"/";
        case ';':
            return @":";
        case '\'':
            return @"\"";
        case '-':
            return @"_";
        case '=':
            return @"+";
        case '\\':
            return @"|";
        case '[':
            return @"{";
        case ']':
            return @"}";
        case '1':
            return @"!";
        case '2':
            return @"@";
        case '3':
            return @"#";
        case '4':
            return @"$";
        case '5':
            return @"%";
        case '6':
            return @"^";
        case '7':
            return @"&";
        case '8':
            return @"*";
        default:
            return str;
    }
}

-(NSString *)currentKeyForKeystrokes:(NSArray *)keys
{
    int a = 0;
    if ([keys containsObject:l1])
        a |= 0x01;
    if ([keys containsObject:l2])
        a |= 0x02;
    if ([keys containsObject:l3])
        a |= 0x04;
    if ([keys containsObject:l4])
        a |= 0x08;
    if ([keys containsObject:r4])
        a |= 0x10;
    if ([keys containsObject:r3])
        a |= 0x20;
    if ([keys containsObject:r2])
        a |= 0x40;
    if ([keys containsObject:r1])
        a |= 0x80;
    
    NSString *ret = [_delegate keySequenceWasPressed:a];
    
    if ([keys containsObject:shift]) {
        if ([ret isEqualToString:[ret uppercaseString]])
            ret = [self convertNonAlphaNumericToShift:ret];
        else
            ret = [ret uppercaseString];
    }
    if ([keys containsObject:shift] && [keys containsObject:space])
        ret = @"\n";
    else if ([keys containsObject:space])
        ret = @" ";
    return ret;
}

-(void)KeyStrokes:(NSArray *)keys
{
    NSString *ret = [self currentKeyForKeystrokes:keys];
    
    if (![ret isEqualToString:@"\b"])
        [_textView insertText:ret];
    else
        [_textView deleteBackward];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL shouldPassToSuper = YES;
    NSArray *array = [touches allObjects];
    for (UITouch *t in array) {
        CGPoint p = [t locationInView:self];
        if (CGRectContainsPoint(shift.frame, p) && [currentKeyStroke containsObject:shift]) {
            [currentKeyStroke removeObject:shift];
            [shift setBackgroundColor:[UIColor clearColor]];
            currentKeys--;
        }
        for (UIView *k in allKeys) {
            if (CGRectContainsPoint(k.frame, p) && ![currentKeyStroke containsObject:k]) {
                shouldPassToSuper = NO;
                [k setBackgroundColor:[UIColor lightGrayColor]];
                [currentKeyStroke addObject:k];
                currentKeys++;
            }
        }
    }
    [self setKeyLabels:currentKeyStroke];
    if (shouldPassToSuper)
        [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *array = [touches allObjects];
    BOOL shouldPassToSuper = YES;
    for (UITouch *t in array) {
        CGPoint p = [t previousLocationInView:self];
        for (UIView *k in allKeys) {
            if (CGRectContainsPoint(k.frame, p) && [currentKeyStroke containsObject:k]) {
                currentKeys--;
                shouldPassToSuper = NO;
            }
        }
    }
    if (currentKeys == 0) {
        [self KeyStrokes:currentKeyStroke];
        for (UIView *k in currentKeyStroke)
            [k setBackgroundColor:[UIColor clearColor]];
        [currentKeyStroke removeAllObjects];
    }
    [self setKeyLabels:currentKeyStroke];
    if (shouldPassToSuper)
        [super touchesBegan:touches withEvent:event];
}

@end
