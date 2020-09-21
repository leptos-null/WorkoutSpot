//
//  WSSegmentStatistics.h
//  WorkoutSpot
//
//  Created by Leptos on 6/11/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <SceneKit/SceneKit.h>
#import <MapKit/MapKit.h>

#import "WSGraphGuide.h"
#import "WSAnalysisDomain.h"

@class WSWorkoutAnalysis;

/// Typed accessors over @c range in @c analysisDomain
/// @discussion @c workoutAnalysis is used to convert
///   between domains where necessary.
@interface WSSegmentStatistics : NSObject

- (instancetype)initWithWorkoutAnalysis:(WSWorkoutAnalysis *)analysis domain:(WSAnalysisDomain *)domain range:(NSRange)range;

@property (strong, nonatomic, readonly) WSWorkoutAnalysis *workoutAnalysis;
@property (strong, nonatomic, readonly) WSAnalysisDomain *analysisDomain;
@property (nonatomic, readonly) NSRange range;

@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) CLLocationDistance deltaDistance;
@property (nonatomic, readonly) CLLocationDistance deltaAltitude;
@property (nonatomic, readonly) double averageGrade;
@property (nonatomic, readonly) CLLocationDistance ascending;
@property (nonatomic, readonly) CLLocationDistance descending;

@property (strong, nonatomic, readonly) MKPolyline *route;
@property (strong, nonatomic, readonly) SCNGeometry *geometry;

@property (nonatomic, readonly) CLLocationSpeed averageSpeed;
@property (nonatomic, readonly) CLLocationSpeed maximumSpeed;
@property (nonatomic, readonly) CLLocationSpeed minimumSpeed;

@property (nonatomic, readonly) CLLocationDistance averageAltitude;
@property (nonatomic, readonly) CLLocationDistance maximumAltitude;
@property (nonatomic, readonly) CLLocationDistance minimumAltitude;

@property (nonatomic, readonly) WSHeartRate averageHeartRate;
@property (nonatomic, readonly) WSHeartRate maximumHeartRate;
@property (nonatomic, readonly) WSHeartRate minimumHeartRate;

- (WSGraphGuide *)speedGraphGuideWithConfiguration:(WSGraphConfiguration *)config;
- (WSGraphGuide *)altitudeGraphGuideWithConfiguration:(WSGraphConfiguration *)config;
- (WSGraphGuide *)heartRateGraphGuideWithConfiguration:(WSGraphConfiguration *)config;

@end
