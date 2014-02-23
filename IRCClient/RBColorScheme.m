//
//  RBColorScheme.m
//  IRCClient
//
//  Created by Rachel Brindle on 2/22/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

#import "RBColorScheme.h"

@implementation RBColorScheme

+(UIColor *)primaryColor
{
    return [[self primaryColors] firstObject];
}

+(UIColor *)secondaryColor
{
    return [[self secondaryColors] firstObject];
}

+(UIColor *)tertiaryColor
{
    if ([[self secondaryColors] count] > 1)
        return [self secondaryColors][1];
    return [self secondaryColor];
}

+(NSArray *)primaryColors
{
    return @[[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1.0]];
}

+(NSArray *)secondaryColors
{
    return @[[UIColor colorWithRed:0 green:0 blue:0.5 alpha:1.0],
             [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1.0]];
}

@end
