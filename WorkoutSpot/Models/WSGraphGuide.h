//
//  WSGraphGuide.h
//  WorkoutSpot
//
//  Created by Leptos on 6/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

#import "WSGraphConfiguration.h"

@interface WSGraphGuide : NSObject

/// @param vector Data to graph, represents the y-values
/// @param config Configuration of the graph
/// @discussion Mutating @c config after calling init does not affect the graph
- (instancetype)initWithVector:(double const *)vector configuration:(WSGraphConfiguration *)config;

/// The size of the graph, including @c insets
@property (nonatomic, readonly) CGSize size;
/// The insets within @c size to draw
@property (nonatomic, readonly) UIEdgeInsets insets;
/// The range of the input data to draw
@property (nonatomic, readonly) NSRange range;

/// A path that represents the data
@property (strong, nonatomic, readonly) UIBezierPath *path;
/// The minimum value in the graph.
/// @discussion Due to smoothing, this may be different
///   from the minimum value of the original input data
@property (nonatomic, readonly) double minimumValue;
/// The maximum value in the graph.
/// @discussion Due to smoothing, this may be different
///   from the maximum value of the original input data
@property (nonatomic, readonly) double maximumValue;

/// The place on the y-axis an x value would be plotted
- (CGFloat)yValueForX:(double)x;
/// The @c x component of @c pointForIndex:
/// @discussion Unlike @c pointForIndex: (which does perform range validation),
///   this method does not perform range validation,
///   and may return a value outside @c path.bounds
- (CGFloat)xForIndex:(NSUInteger)index;
/// The point on @c path where @c index is represented
- (CGPoint)pointForIndex:(NSUInteger)index;

/// Create a circle with radius @c radius around the
/// point where @c index is represented on @c path
- (UIBezierPath *)circleForIndex:(NSUInteger)index radius:(CGFloat)radius;

@end
