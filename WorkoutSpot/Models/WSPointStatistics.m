//
//  WSPointStatistics.m
//  WorkoutSpot
//
//  Created by Leptos on 6/11/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSPointStatistics.h"
#import "WSAnalysisDomain.h"

@implementation WSPointStatistics

- (instancetype)initWithAnalysis:(WSAnalysisDomain *)analysis index:(NSUInteger)idx {
    if (self = [super init]) {
        _analysisDomain = analysis;
        _index = idx;
    }
    return self;
}

- (NSDate *)date {
    NSTimeInterval referenceTime = [self.analysisDomain.time datumAtIndex:self.index];
    return [NSDate dateWithTimeIntervalSinceReferenceDate:referenceTime];
}
- (CLLocationDistance)distance {
    return [self.analysisDomain.distance datumAtIndex:self.index];
}
- (CLLocationSpeed)speed {
    return [self.analysisDomain.speed datumAtIndex:self.index];
}
- (CLLocationDistance)altitude {
    return [self.analysisDomain.altitude datumAtIndex:self.index];
}
- (CLLocationDistance)ascending {
    return [self.analysisDomain.ascending datumAtIndex:self.index];
}
- (double)grade {
    return [self.analysisDomain.grade datumAtIndex:self.index];
}
- (CLLocationCoordinate2D)coordinate {
    return [self.analysisDomain.coordinate coordinateAtIndex:self.index];
}
- (SCNVector3)globePoint {
    return [self.analysisDomain.globeMap pointAtIndex:self.index];
}
- (WSHeartRate)heartRate {
    return [self.analysisDomain.heartRate datumAtIndex:self.index];
}

- (NSString *)description {
    CLLocationCoordinate2D coord = self.coordinate;
    return [NSString stringWithFormat:@"<%@: %p; analysisDomain = %@; index = %lu; "
            "date = %@; distance = %f; speed = %f; altitude = %f; grade = %f; "
            "coordinate = (%f, %f); heartRate = %.0f>",
            [self class], self, self.analysisDomain, self.index,
            self.date, self.distance, self.speed, self.altitude, self.grade,
            coord.latitude, coord.longitude, self.heartRate];
}

@end


@implementation WSAnalysisDomain (WSIndexedSubscript)

- (WSPointStatistics *)objectAtIndexedSubscript:(NSUInteger)idx {
    return [[WSPointStatistics alloc] initWithAnalysis:self index:idx];
}

@end
