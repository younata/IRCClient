//
//  HTAutocompleteTextField.m
//  HotelTonight
//
//  Created by Jonathan Sibley on 11/29/12.
//  Inspired by DOAutocompleteTextField by DoAT.
//
//  Copyright (c) 2012 Hotel Tonight. All rights reserved.
//

#import "HTAutocompleteTextField.h"

#define kHTAutoCompleteButtonWidth  30

static NSObject<HTAutocompleteDataSource> *DefaultAutocompleteDataSource = nil;

@interface HTAutocompleteTextField ()

@property (nonatomic, strong) NSString *autocompleteString;

@end

@implementation HTAutocompleteTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupAutocompleteTextField];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupAutocompleteTextField];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self];
}

- (void)setupAutocompleteTextField
{
    self.autocompleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.autocompleteButton.titleLabel.font = self.font;
    self.autocompleteButton.backgroundColor = [UIColor clearColor];
    [self.autocompleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
    NSLineBreakMode lineBreakMode = NSLineBreakByClipping;
#else
    UILineBreakMode lineBreakMode = UILineBreakModeClip;
#endif
    
    self.autocompleteButton.titleLabel.lineBreakMode = lineBreakMode;
    self.autocompleteButton.hidden = YES;
    [self addSubview:self.autocompleteButton];
    [self bringSubviewToFront:self.autocompleteButton];

    [self.autocompleteButton addTarget:self action:@selector(autocompleteText:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.autocompleteButton];
    [self bringSubviewToFront:self.autocompleteButton];

    self.autocompleteString = @"";
    
    self.ignoreCase = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ht_textDidChange:) name:UITextFieldTextDidChangeNotification object:self];
}

#pragma mark - Configuration

+ (void)setDefaultAutocompleteDataSource:(id)dataSource
{
    DefaultAutocompleteDataSource = dataSource;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self.autocompleteButton.titleLabel setFont:font];
}

#pragma mark - UIResponder

- (BOOL)becomeFirstResponder
{
    // This is necessary because the textfield avoids tapping the autocomplete Button
    [self bringSubviewToFront:self.autocompleteButton];
    if (!self.autocompleteDisabled)
    {
        if ([self clearsOnBeginEditing])
        {
            [self.autocompleteButton setTitle:@"" forState:UIControlStateNormal];
        }
        
        self.autocompleteButton.hidden = NO;
    }
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if (!self.autocompleteDisabled)
    {
        self.autocompleteButton.hidden = YES;

        if ([self commitAutocompleteText]) {
            // Only notify if committing autocomplete actually changed the text.
        

            // This is necessary because committing the autocomplete text changes the text field's text, but for some reason UITextField doesn't post the UITextFieldTextDidChangeNotification notification on its own
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                                object:self];
        }
    }
    return [super resignFirstResponder];
}

#pragma mark - Autocomplete Logic

- (CGRect)autocompleteRectForBounds:(CGRect)bounds
{
    CGRect returnRect = CGRectZero;
    CGRect textRect = [self textRectForBounds:self.bounds];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
    NSLineBreakMode lineBreakMode = NSLineBreakByCharWrapping;
#else
    UILineBreakMode lineBreakMode = UILineBreakModeCharacterWrap;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = lineBreakMode;

    NSDictionary *attributes = @{NSFontAttributeName: self.font,
                                 NSParagraphStyleAttributeName: paragraphStyle};
    CGRect prefixTextRect = [self.text boundingRectWithSize:textRect.size
                                                    options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                 attributes:attributes context:nil];
    CGSize prefixTextSize = prefixTextRect.size;

    CGRect autocompleteTextRect = [self.autocompleteString boundingRectWithSize:CGSizeMake(textRect.size.width-prefixTextSize.width, textRect.size.height)
                                                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                     attributes:attributes context:nil];
    CGSize autocompleteTextSize = autocompleteTextRect.size;
#else
    CGSize prefixTextSize = [self.text sizeWithFont:self.font
                                  constrainedToSize:textRect.size
                                      lineBreakMode:lineBreakMode];

    CGSize autocompleteTextSize = [self.autocompleteString sizeWithFont:self.font
                                                      constrainedToSize:CGSizeMake(textRect.size.width-prefixTextSize.width, textRect.size.height)
                                                          lineBreakMode:lineBreakMode];
#endif
    
    returnRect = CGRectMake(textRect.origin.x + prefixTextSize.width + self.autocompleteTextOffset.x,
                            textRect.origin.y + self.autocompleteTextOffset.y,
                            autocompleteTextSize.width,
                            textRect.size.height);
    
    return returnRect;
}

- (void)ht_textDidChange:(NSNotification*)notification
{
    [self refreshAutocompleteText];
}

- (void)updateAutocompleteLabel
{
    [self.autocompleteButton setTitle:self.autocompleteString forState:UIControlStateNormal];
    [self.autocompleteButton sizeToFit];
    [self.autocompleteButton setFrame:[self autocompleteRectForBounds:self.bounds]];
	
	if ([self.autoCompleteTextFieldDelegate respondsToSelector:@selector(autocompleteTextField:didChangeAutocompleteText:)]) {
		[self.autoCompleteTextFieldDelegate autocompleteTextField:self didChangeAutocompleteText:self.autocompleteString];
	}
}

- (void)refreshAutocompleteText
{
    if (!self.autocompleteDisabled)
    {
        id <HTAutocompleteDataSource> dataSource = nil;
        
        if ([self.autocompleteDataSource respondsToSelector:@selector(textField:completionForPrefix:ignoreCase:)])
        {
            dataSource = (id <HTAutocompleteDataSource>)self.autocompleteDataSource;
        }
        else if ([DefaultAutocompleteDataSource respondsToSelector:@selector(textField:completionForPrefix:ignoreCase:)])
        {
            dataSource = DefaultAutocompleteDataSource;
        }
        
        if (dataSource)
        {
            self.autocompleteString = [dataSource textField:self completionForPrefix:self.text ignoreCase:self.ignoreCase];
            
            [self updateAutocompleteLabel];
        }
    }
}

- (BOOL)commitAutocompleteText
{
    NSString *currentText = self.text;
    if ([self.autocompleteString isEqualToString:@""] == NO
        && self.autocompleteDisabled == NO)
    {
        self.text = [NSString stringWithFormat:@"%@%@", self.text, self.autocompleteString];
        
        self.autocompleteString = @"";
        [self updateAutocompleteLabel];
		
		if ([self.autoCompleteTextFieldDelegate respondsToSelector:@selector(autoCompleteTextFieldDidAutoComplete:)]) {
			[self.autoCompleteTextFieldDelegate autoCompleteTextFieldDidAutoComplete:self];
		}
    }
    return ![currentText isEqualToString:self.text];
}

- (void)forceRefreshAutocompleteText
{
    [self refreshAutocompleteText];
}

#pragma mark - Accessors

- (void)setAutocompleteString:(NSString *)autocompleteString
{
    _autocompleteString = autocompleteString;
}

- (void)setShowAutocompleteButton:(BOOL)showAutocompleteButton
{
    _showAutocompleteButton = showAutocompleteButton;
}

#pragma mark - Private Methods

- (CGRect)frameForAutocompleteButton
{
    CGRect autocompletionButtonRect;
    if (self.clearButtonMode == UITextFieldViewModeNever || self.text.length == 0)
    {
        autocompletionButtonRect = CGRectMake(self.bounds.size.width - kHTAutoCompleteButtonWidth, (self.bounds.size.height/2) - (self.bounds.size.height-8)/2, kHTAutoCompleteButtonWidth, self.bounds.size.height-8);
    }
    else
    {
        autocompletionButtonRect = CGRectMake(self.bounds.size.width - 25 - kHTAutoCompleteButtonWidth, (self.bounds.size.height/2) - (self.bounds.size.height-8)/2, kHTAutoCompleteButtonWidth, self.bounds.size.height-8);
    }
    return autocompletionButtonRect;
}

// Method fired by autocompleteButton for multiRecognition
- (void)autocompleteText:(id)sender
{
    if (!self.autocompleteDisabled)
    {
        self.autocompleteButton.hidden = NO;
        
        [self commitAutocompleteText];
        
        // This is necessary because committing the autocomplete text changes the text field's text, but for some reason UITextField doesn't post the UITextFieldTextDidChangeNotification notification on its own
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                            object:self];
    }
}

@end
