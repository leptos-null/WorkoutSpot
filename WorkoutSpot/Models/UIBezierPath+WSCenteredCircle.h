//
//  UIBezierPath+WSCenteredCircle.h
//  WorkoutSpot
//
//  Created by Leptos on 7/24/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (WSCenteredCircle)

/// Creates and returns a new @c UIBezierPath object initialized
/// with a circle of radius @c radius centered around @c center
+ (instancetype)bezierPathWithCircleCenter:(CGPoint)center radius:(CGFloat)radius;

@end
