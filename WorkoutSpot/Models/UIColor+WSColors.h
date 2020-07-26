//
//  UIColor+WSColors.h
//  WorkoutSpot
//
//  Created by Leptos on 6/5/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (WSColors)

/// Color for elements associated with heart rate
@property (class, nonatomic, readonly) UIColor *heartRateColor;
/// Color for elements associated with speed
@property (class, nonatomic, readonly) UIColor *speedColor;
/// Color for elements associated with altitude
@property (class, nonatomic, readonly) UIColor *altitudeColor;

/// Color for elements associated with an entire route
@property (class, nonatomic, readonly) UIColor *routeColor;
/// Color for elements associated with a segment of a route
@property (class, nonatomic, readonly) UIColor *segmentColor;

@end
