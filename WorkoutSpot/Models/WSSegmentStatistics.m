//
//  WSSegmentStatistics.m
//  WorkoutSpot
//
//  Created by Leptos on 6/11/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSSegmentStatistics.h"
#import "WSAnalysisDomain.h"
#import "WSWorkoutAnalysis.h"

@implementation WSSegmentStatistics {
    NSRange _timeRange;
    NSRange _distanceRange;
}

- (instancetype)initWithWorkoutAnalysis:(WSWorkoutAnalysis *)analysis domain:(WSAnalysisDomain *)domain range:(NSRange)range {
    if (self = [super init]) {
        _workoutAnalysis = analysis;
        _analysisDomain = domain;
        _range = range;
        
        _timeRange = [analysis.timeDomain rangeFromRange:range inDomain:domain];
        _distanceRange = [analysis.timeDomain rangeFromRange:range inDomain:domain];
    }
    return self;
}

- (NSTimeInterval)duration {
    return [self.analysisDomain.time deltaOverRange:self.range];
}
- (CLLocationDistance)deltaDistance {
    return [self.analysisDomain.distance deltaOverRange:self.range];
}
- (CLLocationDistance)deltaAltitude {
    return [self.analysisDomain.altitude deltaOverRange:self.range];
}
- (double)averageGrade {
    WSAnalysisDomain *analysisDomain = self.analysisDomain;
    NSRange range = self.range;
    
    CLLocationDistance rise = [analysisDomain.altitude deltaOverRange:range];
    CLLocationDistance run = [analysisDomain.distance deltaOverRange:range];
    return rise/run;
}
- (CLLocationDistance)ascending {
    return [self.analysisDomain.ascending deltaOverRange:self.range];
}
- (CLLocationDistance)descending {
    return [self.analysisDomain.descending deltaOverRange:self.range];
}

- (MKPolyline *)route {
    return [self.analysisDomain.coordinate polylineForRange:self.range];
}
- (SCNGeometry *)geometry {
    return [self.analysisDomain.globeMap geometryForRange:self.range];
}

- (CLLocationSpeed)averageSpeed {
    WSAnalysisDomain *analysisDomain = self.analysisDomain;
    NSRange range = self.range;
    
    CLLocationDistance dist = [analysisDomain.distance deltaOverRange:range];
    NSTimeInterval time = [analysisDomain.time deltaOverRange:range];
    return dist/time;
}
- (CLLocationSpeed)maximumSpeed {
    return [self.analysisDomain.speed maximumOverRange:self.range];
}
- (CLLocationSpeed)minimumSpeed {
    return [self.analysisDomain.speed minimumOverRange:self.range];
}

- (CLLocationDistance)averageAltitude {
    return [self.analysisDomain.altitude averageOverRange:self.range];
}
- (CLLocationDistance)maximumAltitude {
    return [self.analysisDomain.altitude maximumOverRange:self.range];
}
- (CLLocationDistance)minimumAltitude {
    return [self.analysisDomain.altitude minimumOverRange:self.range];
}

- (WSHeartRate)averageHeartRate {
    WSAnalysisDomain *timeDomain = self.workoutAnalysis.timeDomain;
    return [timeDomain.heartRate averageOverRange:_timeRange];
}
- (WSHeartRate)maximumHeartRate {
    return [self.analysisDomain.heartRate maximumOverRange:self.range];
}
- (WSHeartRate)minimumHeartRate {
    return [self.analysisDomain.heartRate minimumOverRange:self.range];
}

- (WSGraphGuide *)speedGraphGuideWithConfiguration:(WSGraphConfiguration *)config {
    config.range = self.range;
    config.smoothingTechnique = WSGraphSmoothingTechniqueQuadratic;
    return [self.analysisDomain.speed graphGuideForConfiguration:config];
}
- (WSGraphGuide *)altitudeGraphGuideWithConfiguration:(WSGraphConfiguration *)config {
    config.range = self.range;
    config.smoothingTechnique = WSGraphSmoothingTechniqueLinear;
    return [self.analysisDomain.altitude graphGuideForConfiguration:config];
}
- (WSGraphGuide *)heartRateGraphGuideWithConfiguration:(WSGraphConfiguration *)config {
    config.range = self.range;
    config.smoothingTechnique = WSGraphSmoothingTechniqueQuadratic;
    return [self.analysisDomain.heartRate graphGuideForConfiguration:config];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; analysisDomain = %@; range = %@; "
            "duration = %f; deltaDistance = %f; deltaAltitude = %f; "
            "averageGrade = %f; ascending = %f; descending = %f; "
            "averageSpeed = %f; maximumSpeed = %f; minimumSpeed = %f; "
            "maximumAltitude = %f; minimumAltitude = %f; "
            "averageHeartRate = %f; maximumHeartRate = %f; minimumHeartRate = %f>",
            [self class], self, self.analysisDomain, NSStringFromRange(self.range),
            self.duration, self.deltaDistance, self.deltaAltitude,
            self.averageGrade, self.ascending, self.descending,
            self.averageSpeed, self.maximumSpeed, self.minimumSpeed,
            self.maximumAltitude, self.minimumAltitude,
            self.averageHeartRate, self.maximumHeartRate, self.minimumHeartRate];
}

@end
