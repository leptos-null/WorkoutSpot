//
//  WSHashWorkout.m
//  WorkoutSpot
//
//  Created by Leptos on 7/31/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSHashWorkout.h"

@implementation WSHashWorkout

- (instancetype)initWithWorkout:(HKWorkout *)workout {
    if (self = [super init]) {
        _workout = workout;
    }
    return self;
}

- (NSUUID *)UUID {
    return self.workout.UUID;
}

// MARK: - Hashing

- (NSUInteger)hash {
    return self.UUID.hash;
}
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        __typeof(self) casted = object;
        return [self.UUID isEqual:casted.UUID];
    }
    return NO;
}

@end
