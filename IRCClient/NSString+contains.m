#import "NSString+contains.h"

@implementation NSString (contains)

-(BOOL)containsSubstring:(NSString *)substring
{
    if (substring == nil)
        return NO;
    return [self rangeOfString:substring].location != NSNotFound;
}

@end
