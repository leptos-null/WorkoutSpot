//
//  WSWorkoutData.m
//  WorkoutSpot
//
//  Created by Leptos on 8/30/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSWorkoutData.h"

static NSString *const WSWorkoutDataWorkoutKey = @"WSWorkoutDataWorkoutKey";
static NSString *const WSWorkoutDataLocationsKey = @"WSWorkoutDataLocationsKey";
static NSString *const WSWorkoutDataHeartRatesKey = @"WSWorkoutDataHeartRatesKey";

@implementation WSWorkoutData

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.workout forKey:WSWorkoutDataWorkoutKey];
    [coder encodeObject:self.locations forKey:WSWorkoutDataLocationsKey];
    [coder encodeObject:self.heartRates forKey:WSWorkoutDataHeartRatesKey];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSArray<Class> *locationClasses = @[
        [NSArray class],
        [CLLocation class]
    ];
    NSArray<Class> *heartRateClasses = @[
        [NSArray class],
        [HKDiscreteQuantitySample class]
    ];
    return [self initWithWorkout:[coder decodeObjectOfClass:[HKWorkout class] forKey:WSWorkoutDataWorkoutKey]
                       locations:[coder decodeObjectOfClasses:[NSSet setWithArray:locationClasses] forKey:WSWorkoutDataLocationsKey]
                      heartRates:[coder decodeObjectOfClasses:[NSSet setWithArray:heartRateClasses] forKey:WSWorkoutDataHeartRatesKey]];
}

- (instancetype)initWithWorkout:(HKWorkout *)workout locations:(NSArray<CLLocation *> *)locations heartRates:(NSArray<HKDiscreteQuantitySample *> *)heartRates {
    if (self = [super init]) {
        _workout = workout;
        _locations = locations;
        _heartRates = heartRates;
    }
    return self;
}

@end

@implementation WSWorkoutData (WSCodingConvenience)

+ (instancetype)workoutDataFromArchivedData:(NSData *)data error:(NSError **)error {
    return [NSKeyedUnarchiver unarchivedObjectOfClass:self fromData:data error:error];
}
- (NSData *)archivedDataError:(NSError **)error {
    return [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:error];
}

@end
