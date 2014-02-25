//
//  RBScriptHelpers.h
//  IRCClient
//
//  Created by Rachel Brindle on 2/22/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSAttributedStringAttributes : NSObject

+(NSString *)NSFontAttributeName;
+(NSString *)NSParagraphStyleAttributeName;
+(NSString *)NSForegroundColorAttributeName;
+(NSString *)NSBackgroundColorAttributeName;
+(NSString *)NSLigatureAttributeName;
+(NSString *)NSKernAttributeName;
+(NSString *)NSStrikethroughStyleAttributeName;
+(NSString *)NSUnderlineStyleAttributeName;
+(NSString *)NSStrokeColorAttributeName;
+(NSString *)NSStrokeWidthAttributeName;
+(NSString *)NSShadowAttributeName;
+(NSString *)NSTextEffectAttributeName;
+(NSString *)NSAttachmentAttributeName;
+(NSString *)NSLinkAttributeName;
+(NSString *)NSBaselineOffsetAttributeName;
+(NSString *)NSUnderlineColorAttributeName;
+(NSString *)NSStrikethroughColorAttributeName;
+(NSString *)NSObliquenessAttributeName;
+(NSString *)NSExpansionAttributeName;
+(NSString *)NSWritingDirectionAttributeName;
+(NSString *)NSVerticalGlyphFormAttributeName;

+(NSInteger)UIControlEventTouchDown;
+(NSInteger)UIControlEventTouchDownRepeat;
+(NSInteger)UIControlEventTouchDragInside;
+(NSInteger)UIControlEventTouchDragOutside;
+(NSInteger)UIControlEventTouchDragEnter;
+(NSInteger)UIControlEventTouchDragExit;
+(NSInteger)UIControlEventTouchUpInside;
+(NSInteger)UIControlEventTouchUpOutside;
+(NSInteger)UIControlEventTouchCancel;
+(NSInteger)UIControlEventValueChanged;
+(NSInteger)UIControlEventEditingDidBegin;
+(NSInteger)UIControlEventEditingChanged;
+(NSInteger)UIControlEventEditingDidEnd;
+(NSInteger)UIControlEventEditingDidEndOnExit;
+(NSInteger)UIControlEventAllTouchEvents;
+(NSInteger)UIControlEventAllEditingEvents;
+(NSInteger)UIControlEventApplicationReserved;
+(NSInteger)UIControlEventSystemReserved;
+(NSInteger)UIControlEventAllEvents;

@end
