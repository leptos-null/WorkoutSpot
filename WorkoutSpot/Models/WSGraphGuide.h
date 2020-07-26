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

@interface WSGraphGuide : NSObject

/// @param vector data to graph
/// @param size complete size of the graph
/// @param insets insets within @c size to draw
/// @param range the portion of @c vector to graph
- (instancetype)initWithVector:(double const *)vector size:(CGSize)size insets:(UIEdgeInsets)insets range:(NSRange)range;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) UIEdgeInsets insets;
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
/// The point on @c path where @c index is represented
- (CGPoint)pointForIndex:(NSUInteger)index;

@end
