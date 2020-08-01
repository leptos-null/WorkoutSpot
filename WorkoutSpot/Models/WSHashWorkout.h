//
//  WSHashWorkout.h
//  WorkoutSpot
//
//  Created by Leptos on 7/31/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

/// A wrapper around @c HKWorkout with guaranteed hashing behaviors
@interface WSHashWorkout : NSObject

/// A workout the receiver represents
@property (strong, nonatomic, readonly) HKWorkout *workout;
/// A UUID for which all hashing is forwarded to
@property (strong, nonatomic, readonly) NSUUID *UUID;

/// Create an instance with the specified workout
- (instancetype)initWithWorkout:(HKWorkout *)workout;

@end
