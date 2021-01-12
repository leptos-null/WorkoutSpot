//
//  WSWorkoutFetch.m
//  WorkoutSpot
//
//  Created by Leptos on 8/30/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSWorkoutFetch.h"
#import "../Models/HKObjectType+WSTypes.h"

@implementation WSWorkoutFetch

+ (NSSet<HKSampleType *> *)sampleTypes {
    NSArray<HKSampleType *> *types = @[
        [HKWorkoutType workoutType],
        [HKQuantityType heartRateType],
        [HKSeriesType workoutRouteType]
    ];
    return [NSSet setWithArray:types];
}

+ (void)getDataForWorkout:(HKWorkout *)workout healthStore:(HKHealthStore *)healthStore completion:(void (^)(WSWorkoutData *, NSError *))handler {
    NSPredicate *predicate = [HKQuery predicateForObjectsFromWorkout:workout];
    
    NSMutableArray<HKDiscreteQuantitySample *> *heartRates = [NSMutableArray array];
    NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
    
    __block BOOL heartRatesDone = NO;
    __block BOOL locationsDone = NO;
    
    void(^callHandlerIfDone)() = ^{
        if (heartRatesDone && locationsDone) {
            WSWorkoutData *workoutData = [[WSWorkoutData alloc] initWithWorkout:workout locations:[locations copy] heartRates:[heartRates copy]];
            handler(workoutData, nil);
        }
    };
    
    HKQuantityType *quantityType = [HKQuantityType heartRateType];
    HKQuantitySeriesSampleQuery *heartQuery = [[HKQuantitySeriesSampleQuery alloc] initWithQuantityType:quantityType predicate:predicate quantityHandler:^(HKQuantitySeriesSampleQuery *query, HKQuantity *quantity, NSDateInterval *dateInterval, __kindof HKQuantitySample *quantitySample, BOOL done, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        // seemingly, if there are no heart rate samples that match the query,
        // the handler is called once with (self, nil, nil, nil, YES, nil)
        if (quantity != nil) {
            HKDiscreteQuantitySample *discreteSample = [HKDiscreteQuantitySample quantitySampleWithType:quantityType quantity:quantity
                                                                                              startDate:dateInterval.startDate endDate:dateInterval.endDate];
            
            [heartRates addObject:discreteSample];
        }
        if (done) {
            heartRatesDone = YES;
            dispatch_async(dispatch_get_main_queue(), callHandlerIfDone);
        }
    }];
    
    HKSeriesType *sampleType = [HKSeriesType workoutRouteType];
    HKSampleQuery *routeQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES]
    ] resultsHandler:^(HKSampleQuery *query, NSArray<HKWorkoutRoute *> *workoutRoutes, NSError *queryError) {
        if (queryError) {
            handler(nil, queryError);
            return;
        }
        
        __block NSUInteger completeCount = 0;
        NSUInteger const routeCount = workoutRoutes.count;
        NSMutableArray<NSArray<CLLocation *> *> *routeLocations = [NSMutableArray arrayWithCapacity:routeCount];
        if (routeCount == 0) {
            locationsDone = YES;
            dispatch_async(dispatch_get_main_queue(), callHandlerIfDone);
            return;
        }
        // fill the array so we can write to any index later
        for (NSUInteger routeIdx = 0; routeIdx < routeCount; routeIdx++) {
            routeLocations[routeIdx] = @[];
        }
        
        [workoutRoutes enumerateObjectsUsingBlock:^(HKWorkoutRoute *route, NSUInteger idx, BOOL *stop) {
            [self locationsForRoute:route healthStore:healthStore handler:^(NSArray<CLLocation *> *locs, NSError *error) {
                if (error) {
                    handler(nil, error);
                    return;
                }
                // this handler can be called in any order
                // use a second array to enforce the order
                routeLocations[idx] = locs;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // keep track of how many routes have been processed,
                    // so we know when they're all done
                    completeCount++;
                    if (completeCount == routeCount) {
                        for (NSArray<CLLocation *> *location in routeLocations) {
                            [locations addObjectsFromArray:location];
                        }
                        
                        locationsDone = YES;
                        callHandlerIfDone();
                    }
                });
            }];
        }];
    }];
    
    [healthStore executeQuery:heartQuery];
    [healthStore executeQuery:routeQuery];
}

+ (void)locationsForRoute:(HKWorkoutRoute *)route healthStore:(HKHealthStore *)healthStore
                  handler:(void(^)(NSArray<CLLocation *> *locations, NSError *error))handler {
    NSMutableArray<CLLocation *> *locations = [NSMutableArray arrayWithCapacity:route.count];
    // I'm not clear if this is guaranteed to be in chronological order, but for now we're assuming it is
    HKWorkoutRouteQuery *routeQuery = [[HKWorkoutRouteQuery alloc] initWithRoute:route
                                                dataHandler:^(HKWorkoutRouteQuery *query, NSArray<CLLocation *> *routePoints, BOOL done, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        }
        [locations addObjectsFromArray:routePoints];
        if (done) {
            handler(locations, nil);
        }
    }];
    [healthStore executeQuery:routeQuery];
}

+ (void)writeWorkoutData:(WSWorkoutData *)workoutData toHealthStore:(HKHealthStore *)healthStore completion:(void (^)(BOOL, NSError *))handler {
    NSSet<HKSampleType *> *readWrite = [self sampleTypes];
    [healthStore requestAuthorizationToShareTypes:readWrite readTypes:readWrite completion:^(BOOL authSuccess, NSError *authError) {
        if (authError) {
            handler(authSuccess, authError);
            return;
        }
        if (authSuccess) {
            HKWorkout *workout = workoutData.workout; // get a new UUID
            workout = [HKWorkout workoutWithActivityType:workout.workoutActivityType
                                               startDate:workout.startDate endDate:workout.endDate
                                           workoutEvents:workout.workoutEvents
                                       totalEnergyBurned:workout.totalEnergyBurned totalDistance:workout.totalDistance
                                                metadata:workout.metadata];
            
            [healthStore saveObject:workout withCompletion:^(BOOL saveSuccess, NSError *saveError) {
                if (saveError) {
                    handler(saveSuccess, saveError);
                    return;
                }
                if (saveSuccess) {
                    __block BOOL heartRatesAdded = NO;
                    __block BOOL locationsAdded = NO;
                    
                    void(^callHandlerIfDone)() = ^{
                        if (heartRatesAdded && locationsAdded) {
                            handler(YES, nil);
                        }
                    };
                    
                    HKWorkoutRouteBuilder *builder = [[HKWorkoutRouteBuilder alloc] initWithHealthStore:healthStore device:nil];
                    [builder insertRouteData:workoutData.locations completion:^(BOOL routeInsertSuccess, NSError *routeInsertError) {
                        if (routeInsertError) {
                            handler(routeInsertSuccess, routeInsertError);
                            return;
                        }
                        if (routeInsertSuccess) {
                            [builder finishRouteWithWorkout:workout metadata:nil completion:^(HKWorkoutRoute *workoutRoute, NSError *error) {
                                if (error) {
                                    handler(workoutRoute != nil, error);
                                    return;
                                }
                                
                                locationsAdded = YES;
                                dispatch_async(dispatch_get_main_queue(), callHandlerIfDone);
                            }];
                        }
                    }];
                    
                    [healthStore addSamples:workoutData.heartRates toWorkout:workout completion:^(BOOL success, NSError *error) {
                        if (error) {
                            handler(success, error);
                            return;
                        }
                        if (success) {
                            heartRatesAdded = YES;
                            dispatch_async(dispatch_get_main_queue(), callHandlerIfDone);
                        }
                    }];
                }
            }];
        }
    }];
}

@end
