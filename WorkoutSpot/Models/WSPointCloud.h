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

@interface WSPointCloud : NSObject

- (instancetype)initWithPoints:(const SCNVector3 *)vectors length:(const NSUInteger)length;

- (SCNVector3)pointAtIndex:(NSUInteger)index;

/// Computes the distance between @c vectors in three-dimensional space
/// @code
/// spacing[n] = vectors[n] - vectors[n - 1]
/// @endcode
- (WSDataAnalysis *)stepSpace;

- (SCNGeometry *)geometryForRange:(NSRange)range;

@end
