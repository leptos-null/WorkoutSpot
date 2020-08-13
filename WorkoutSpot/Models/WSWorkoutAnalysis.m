//
//  WSWorkoutAnalysis.m
//  WorkoutSpot
//
//  Created by Leptos on 6/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSWorkoutAnalysis.h"
#import "WSStampedQuantity.h"
#import "HKObjectType+WSTypes.h"

@implementation WSWorkoutAnalysis {
    NSArray<CLLocation *> *_queuedLocations;
    NSArray<WSStampedQuantity *> *_queuedQuantities;
    NSError *_queuedError;
    WSWorkoutAnalysisComplete _handler;
}

- (instancetype)initWithWorkout:(HKWorkout *)workout store:(HKHealthStore *)store {
    if (self = [super init]) {
        _workout = workout;
        _healthStore = store;
        
        [self _startHeartQuery];
        [self _startRouteQuery];
    }
    return self;
}

- (void)_startHeartQuery {
    __weak __typeof(self) weakself = self;
    NSMutableArray<WSStampedQuantity *> *heartRates = [NSMutableArray array];
    
    NSPredicate *predicate = [HKQuery predicateForObjectsFromWorkout:self.workout];
    HKQuantityType *quantityType = [HKQuantityType heartRateType];
    HKQuantitySeriesSampleQuery *heartQuery = [[HKQuantitySeriesSampleQuery alloc] initWithQuantityType:quantityType predicate:predicate quantityHandler:^(HKQuantitySeriesSampleQuery *query, HKQuantity *quantity, NSDateInterval *dateInterval, __kindof HKQuantitySample *quantitySample, BOOL done, NSError *error) {
        if (error) {
            weakself.queuedError = error;
            return;
        }
        // seemingly, if there are no heart rate samples that match the query,
        // the handler is called once with (self, nil, nil, nil, YES, nil)
        if (quantity != nil) {
            WSStampedQuantity *stampedQuantity = [[WSStampedQuantity alloc] initWithQuantity:quantity dateInterval:dateInterval];
            [heartRates addObject:stampedQuantity];
        }
        if (done) {
            self.queuedQuantities = heartRates;
        }
    }];
    [self.healthStore executeQuery:heartQuery];
}

- (void)_startRouteQuery {
    __weak __typeof(self) weakself = self;
    NSPredicate *predicate = [HKQuery predicateForObjectsFromWorkout:self.workout];
    HKSeriesType *sampleType = [HKSeriesType workoutRouteType];
    HKSampleQuery *routeQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES]
    ] resultsHandler:^(HKSampleQuery *query, NSArray<__kindof HKSample *> *workoutRoutes, NSError *error) {
        if (error) {
            weakself.queuedError = error;
            return;
        }
        [weakself locationsForRoutes:workoutRoutes handler:^(NSArray<CLLocation *> *locations, NSError *flattenErr) {
            if (flattenErr) {
                weakself.queuedError = flattenErr;
                return;
            }
            weakself.queuedLocation = locations;
        }];
    }];
    [self.healthStore executeQuery:routeQuery];
}

- (void)locationsForRoutes:(NSArray<HKWorkoutRoute *> *)routes handler:(void(^)(NSArray<CLLocation *> *locations, NSError *error))handler {
    __weak __typeof(self) weakself = self;
    __block NSUInteger lineCount = 0;
    NSUInteger const routeCount = routes.count;
    NSMutableArray<NSArray<CLLocation *> *> *locations = [NSMutableArray arrayWithCapacity:routeCount];
    for (NSUInteger routeIdx = 0; routeIdx < routeCount; routeIdx++) {
        locations[routeIdx] = @[];
    }
    
    [routes enumerateObjectsUsingBlock:^(HKWorkoutRoute *route, NSUInteger idx, BOOL *stop) {
        [weakself locationsForRoute:route handler:^(NSArray<CLLocation *> *locs, NSError *error) {
            if (error) {
                handler(nil, error);
                return;
            }
            // this handler can be called in any order
            // use a second array to enforce the order
            locations[idx] = locs;
            dispatch_async(dispatch_get_main_queue(), ^{
                lineCount++;
                if (lineCount == routeCount) {
                    NSMutableArray<CLLocation *> *flat = [NSMutableArray array];
                    for (NSArray<CLLocation *> *location in locations) {
                        [flat addObjectsFromArray:location];
                    }
                    handler(flat, nil);
                }
            });
        }];
    }];
}

- (void)locationsForRoute:(HKWorkoutRoute *)route handler:(void(^)(NSArray<CLLocation *> *locations, NSError *error))handler {
    NSMutableArray<CLLocation *> *locations = [NSMutableArray arrayWithCapacity:route.count];
    // I'm not clear if this is guaranteed to be in chronological order, but for now we're assuming it is
    HKWorkoutRouteQuery *routeQuery = [[HKWorkoutRouteQuery alloc] initWithRoute:route dataHandler:^(HKWorkoutRouteQuery *query, NSArray<CLLocation *> *routePoints, BOOL done, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        [locations addObjectsFromArray:routePoints];
        if (done) {
            handler(locations, nil);
        }
    }];
    [self.healthStore executeQuery:routeQuery];
}

- (void)_coalesceDispatchGuaranteedMain {
    if (_handler != NULL) {
        if (_queuedLocations != nil && _queuedQuantities != nil) {
            HKWorkout *workout = self.workout;
            _timeDomain = [[WSAnalysisDomain alloc] initTimeDomainWithLocations:_queuedLocations
                                                                   heartSamples:_queuedQuantities
                                                                      startDate:workout.startDate endDate:workout.endDate];
            _distanceDomain = [[WSAnalysisDomain alloc] initWithDomain:_timeDomain key:WSDomainKeyDistance];
            
            _queuedLocations = nil;
            _queuedQuantities = nil;
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

- (void)setQueuedLocation:(NSArray<CLLocation *> *)queuedLocation {
    _queuedLocations = queuedLocation;
    [self _coalesceDispatch];
}
- (void)setQueuedQuantities:(NSArray<WSStampedQuantity *> *)queuedQuantities {
    _queuedQuantities = queuedQuantities;
    [self _coalesceDispatch];
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
    return [NSString stringWithFormat:@"<%@: %p; workout = %@; healthStore = %@; "
            "timeDomain = %@; distanceDomain = %@>",
            [self class], self, self.workout, self.healthStore,
            self.timeDomain, self.distanceDomain];
}

@end
