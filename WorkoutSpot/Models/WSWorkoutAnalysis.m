//
//  WSWorkoutAnalysis.m
//  WorkoutSpot
//
//  Created by Leptos on 6/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSWorkoutAnalysis.h"
#import "../Services/WSWorkoutFetch.h"

@implementation WSWorkoutAnalysis {
    WSWorkoutData *_workoutData;
    NSError *_queuedError;
    WSWorkoutAnalysisComplete _handler;
}

- (instancetype)initWithWorkout:(HKWorkout *)workout store:(HKHealthStore *)store {
    if (self = [super init]) {
        _workout = workout;
        
        __weak __typeof(self) weakself = self;
        [WSWorkoutFetch getDataForWorkout:workout healthStore:store completion:^(WSWorkoutData *workoutData, NSError *error) {
            weakself.workoutData = workoutData;
            weakself.queuedError = error;
        }];
    }
    return self;
}

- (void)_coalesceDispatchGuaranteedMain {
    if (_handler != NULL) {
        WSWorkoutData *workoutData = _workoutData;
        if (workoutData != nil) {
            HKWorkout *workout = self.workout;
            _timeDomain = [[WSAnalysisDomain alloc] initTimeDomainWithLocations:workoutData.locations
                                                                   heartSamples:workoutData.heartRates
                                                                      startDate:workout.startDate endDate:workout.endDate];
            _distanceDomain = [[WSAnalysisDomain alloc] initWithDomain:_timeDomain key:WSDomainKeyDistance];
            
            _workoutData = nil;
        }
        
        if (self.timeDomain != nil && self.distanceDomain != nil) {
            _handler(self, nil);
            _handler = nil;
        } else if (_queuedError != nil) {
            _handler(self, _queuedError);
            _handler = nil;
        }
    }
}
- (void)_coalesceDispatch {
    __weak __typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself _coalesceDispatchGuaranteedMain];
    });
}
- (void)setWorkoutData:(WSWorkoutData *)workoutData {
    _workoutData = workoutData;
    [self _coalesceDispatchGuaranteedMain];
}
- (void)setQueuedError:(NSError *)queuedError {
    _queuedError = queuedError;
    [self _coalesceDispatch];
}
- (void)setHandler:(WSWorkoutAnalysisComplete)handler {
    _handler = handler;
    [self _coalesceDispatch];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; workout = %@; timeDomain = %@; distanceDomain = %@>",
            [self class], self, self.workout, self.timeDomain, self.distanceDomain];
}

@end
