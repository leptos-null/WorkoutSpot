//
//  UIColor+WSColors.m
//  WorkoutSpot
//
//  Created by Leptos on 6/5/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "UIColor+WSColors.h"

@implementation UIColor (WSColors)

+ (UIColor *)heartRateColor {
    return [self systemRedColor];
}
+ (UIColor *)speedColor {
    return [self systemBlueColor];
}
+ (UIColor *)altitudeColor {
    return [self systemOrangeColor];
}

+ (UIColor *)routeColor {
    return [self systemIndigoColor];
}
+ (UIColor *)segmentColor {
    return [self systemGreenColor];
}

@end
