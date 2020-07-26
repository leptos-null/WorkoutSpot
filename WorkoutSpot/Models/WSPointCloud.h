//
//  WSPointCloud.h
//  WorkoutSpot
//
//  Created by Leptos on 7/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface WSPointCloud : NSObject

- (instancetype)initWithPoints:(const SCNVector3 *)vectors length:(const NSUInteger)length;

- (SCNVector3)pointAtIndex:(NSUInteger)index;

/// Sums the distance between each point in @c range
- (float)rollingDistanceOverRange:(NSRange)range;

- (SCNGeometry *)geometryForRange:(NSRange)range;

@end
