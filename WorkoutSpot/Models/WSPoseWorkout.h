//
//  WSPoseWorkout.h
//  WorkoutSpot
//
//  Created by Leptos on 7/31/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSHashWorkout.h"

/// A @c WSHashWorkout capable as posing as a real workout for hashing purposes
@interface WSPoseWorkout : WSHashWorkout

/// Create an object posing as a workout with @c UUID
- (instancetype)initWithWorkoutUUID:(NSUUID *)UUID;

@end
