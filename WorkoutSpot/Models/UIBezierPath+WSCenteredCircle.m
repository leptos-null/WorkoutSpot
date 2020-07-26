//
//  UIBezierPath+WSCenteredCircle.m
//  WorkoutSpot
//
//  Created by Leptos on 7/24/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "UIBezierPath+WSCenteredCircle.h"

@implementation UIBezierPath (WSCenteredCircle)

+ (instancetype)bezierPathWithCircleCenter:(CGPoint)center radius:(CGFloat)radius {
    CGFloat diameter = radius * 2;
    CGRect rect;
    rect.origin.x = center.x - radius;
    rect.origin.y = center.y - radius;
    rect.size.width = diameter;
    rect.size.height = diameter;
    return [self bezierPathWithOvalInRect:rect];
}

@end
