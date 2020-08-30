//
//  WSWorkoutFetch.h
//  WorkoutSpot
//
//  Created by Leptos on 8/30/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Models/WSWorkoutData.h"

@interface WSWorkoutFetch : NSObject

/// Sample types that the app uses
+ (NSSet<HKSampleType *> *)sampleTypes;

+ (void)getDataForWorkout:(HKWorkout *)workout healthStore:(HKHealthStore *)healthStore completion:(void(^)(WSWorkoutData *workoutData, NSError *error))handler;
+ (void)writeWorkoutData:(WSWorkoutData *)workoutData toHealthStore:(HKHealthStore *)healthStore completion:(void(^)(BOOL success, NSError *error))handler;

@end
