//
//  WSPoseWorkout.m
//  WorkoutSpot
//
//  Created by Leptos on 7/31/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSPoseWorkout.h"

@implementation WSPoseWorkout {
    NSUUID *_UUID;
}

- (instancetype)initWithWorkoutUUID:(NSUUID *)UUID {
    if (self = [super init]) {
        _UUID = UUID;
    }
    return self;
}

- (NSUUID *)UUID {
    return _UUID;
}

@end
