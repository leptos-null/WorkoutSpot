//
//  WSWorkoutData.h
//  WorkoutSpot
//
//  Created by Leptos on 8/30/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <HealthKit/HealthKit.h>
#import <CoreLocation/CoreLocation.h>

/// Workout data available for synchronous access.
/// Get one from @c WSWorkoutFetch
@interface WSWorkoutData : NSObject <NSSecureCoding>

@property (strong, nonatomic, readonly) HKWorkout *workout;
@property (strong, nonatomic, readonly) NSArray<CLLocation *> *locations;
@property (strong, nonatomic, readonly) NSArray<HKDiscreteQuantitySample *> *heartRates;

- (instancetype)initWithWorkout:(HKWorkout *)workout locations:(NSArray<CLLocation *> *)locations heartRates:(NSArray<HKDiscreteQuantitySample *> *)heartRates;

@end

@interface WSWorkoutData (WSCodingConvenience)

+ (instancetype)workoutDataFromArchivedData:(NSData *)data error:(NSError **)error;
- (NSData *)archivedDataError:(NSError **)error;

@end
