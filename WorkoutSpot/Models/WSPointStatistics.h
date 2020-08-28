//
//  WSPointStatistics.h
//  WorkoutSpot
//
//  Created by Leptos on 6/11/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <SceneKit/SceneKit.h>

#import "WSAnalysisDomain.h"

/// Typed accessors for @c index in @c analysisDomain
@interface WSPointStatistics : NSObject

- (instancetype)initWithAnalysis:(WSAnalysisDomain *)analysis index:(NSUInteger)idx;

@property (strong, nonatomic, readonly) WSAnalysisDomain *analysisDomain;
@property (nonatomic, readonly) NSUInteger index;

@property (strong, nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) CLLocationDistance distance;
@property (nonatomic, readonly) CLLocationSpeed speed;
@property (nonatomic, readonly) CLLocationDistance altitude;
@property (nonatomic, readonly) CLLocationDistance ascending;
@property (nonatomic, readonly) double grade;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) SCNVector3 globePoint;
@property (nonatomic, readonly) WSHeartRate heartRate;

@end


@interface WSAnalysisDomain (WSIndexedSubscript)

- (WSPointStatistics *)objectAtIndexedSubscript:(NSUInteger)idx;

@end
