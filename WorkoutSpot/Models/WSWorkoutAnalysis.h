//
//  WSWorkoutAnalysis.h
//  WorkoutSpot
//
//  Created by Leptos on 6/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

#import "WSAnalysisDomain.h"

@interface WSWorkoutAnalysis : NSObject

typedef void(^WSWorkoutAnalysisComplete)(WSWorkoutAnalysis *analysis, NSError *error);

/// Begin analyzing @c workout using @c store for additional queries
- (instancetype)initWithWorkout:(HKWorkout *)workout store:(HKHealthStore *)store;

@property (strong, nonatomic, readonly) HKWorkout *workout;

/// Analysis of @c workout in the time domain
@property (strong, nonatomic, readonly) WSAnalysisDomain *timeDomain;
/// Analysis of @c workout in the distance domain
@property (strong, nonatomic, readonly) WSAnalysisDomain *distanceDomain;

- (WSAnalysisDomain *)domainForKey:(WSDomainKey)key;

/// The handler called upon completion
///   of @c timeDomain and @c distanceDomain
///   being calculated. The handler may be set
///   multiple times. Each time the handler is
///   set, the handler may be called once. The
///   handler will be called on the main thread.
- (void)setHandler:(WSWorkoutAnalysisComplete)handler;

@end
