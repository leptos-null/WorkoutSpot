//
//  WSPointCloud.h
//  WorkoutSpot
//
//  Created by Leptos on 7/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "WSDataAnalysis.h"

/// An array of points in 3-dimensional space
@interface WSPointCloud : NSObject

- (instancetype)initWithPoints:(const SCNVector3 *)vectors length:(const NSUInteger)length;
/// The point at @c index
- (SCNVector3)pointAtIndex:(NSUInteger)index;

/// Computes the distance between @c vectors in three-dimensional space
/// @code
/// spacing[n] = vectors[n] - vectors[n - 1]
/// @endcode
- (WSDataAnalysis *)stepSpace;
/// Geometry of the points within @c range
- (SCNGeometry *)geometryForRange:(NSRange)range;

@end
