//
//  WSAnalysisDomain.m
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSAnalysisDomain.h"

NSString *NSStringFromWSDomainKey(WSDomainKey key) {
    switch (key) {
        case WSDomainKeyTime:
            return @"Time";
        case WSDomainKeyDistance:
            return @"Distance";
        case WSDomainKeyClimbing:
            return @"Climbing";
        default:
            return nil;
    }
}

@implementation WSAnalysisDomain

// WSHeartRate
- (HKUnit *)_heartRateUnit {
    static HKUnit *unit;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HKUnit *beats = [HKUnit countUnit];
        HKUnit *timeInterval = [HKUnit secondUnit]; // NSTimeInterval
        unit = [beats unitDividedByUnit:timeInterval];
    });
    return unit;
}

// TODO: Consider os_signpost benchmarks

- (instancetype)initTimeDomainWithLocations:(NSArray<CLLocation *> *)locations
                               heartSamples:(NSArray<HKDiscreteQuantitySample *> *)quantities
                                  startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    if (self = [super init]) {
        NSUInteger locationCount = locations.count;
        
        // when `locations[0].timestamp < startDate`, then distance data
        // starts with a non-zero value which is problematic.
        // (only 0 distance should be traveled in 0 time)
        NSTimeInterval const startIntervalSinceReferenceDate = startDate.timeIntervalSinceReferenceDate;
        NSUInteger locationFirstIndex = [locations indexOfObjectPassingTest:^BOOL(CLLocation *location, NSUInteger idx, BOOL *stop) {
            return (location.timestamp.timeIntervalSinceReferenceDate >= startIntervalSinceReferenceDate);
        }];
        
        if (locationFirstIndex != 0) { // avoid copying if possible
            locationCount -= locationFirstIndex;
            // if this were a C array, we could just increment the pointer, and we'd be done
            // this is essentially a copy operation- it accounts for about 2.5% of the executation time of this method
            // the other option is to change every access of `locations` to add `locationFirstIndex` to the index
            locations = [locations subarrayWithRange:NSMakeRange(locationFirstIndex, locationCount)];
        }
        
        NSTimeInterval timeOffset = startDate.timeIntervalSinceReferenceDate;
        timeOffset = -timeOffset; // we want to subtract, not add
        NSTimeInterval const timeDomainLength = endDate.timeIntervalSinceReferenceDate + timeOffset;
        
        CLLocationDistance *distances = malloc(locationCount * sizeof(CLLocationDistance));
        CLLocationDistance *altitudes = malloc(locationCount * sizeof(CLLocationDistance));
        CLLocationCoordinate2D *coordinates = malloc(locationCount * sizeof(CLLocationCoordinate2D));
        NSTimeInterval *locationStamps = malloc(locationCount * sizeof(NSTimeInterval));
        
        distances[0] = 0;
        [locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
            altitudes[idx] = location.altitude;
            coordinates[idx] = location.coordinate;
            locationStamps[idx] = location.timestamp.timeIntervalSinceReferenceDate;
            
            if (idx != 0) {
                distances[idx] = distances[idx - 1] + [location distanceFromLocation:locations[idx - 1]];
            }
        }];
        
        NSTimeInterval *locationIndx = malloc(locationCount * sizeof(NSTimeInterval));
        vDSP_vsaddD(locationStamps, 1, &timeOffset, locationIndx, 1, locationCount);
        
        _domainKey = WSDomainKeyTime;
        _fullRange = NSMakeRange(0, ceil(timeDomainLength));
        
        _time = [[WSDataAnalysis alloc] initWithData:locationStamps keys:locationIndx domain:timeDomainLength length:locationCount];
        
        _distance = [[WSDataAnalysis alloc] initWithData:distances keys:locationIndx domain:timeDomainLength length:locationCount];
        
        _altitude = [[WSDataAnalysis alloc] initWithData:altitudes keys:locationIndx domain:timeDomainLength length:locationCount];
        _coordinate = [[WSCoordinateAnalysis alloc] initWithCoordinates:coordinates keys:locationIndx domain:timeDomainLength length:locationCount];
        _globeMap = [_coordinate globeMapForAltitudes:_altitude];
        
        _speed = [_distance derivative];
        _grade = [_altitude derivativeInDomain:_distance];
        
        WSDataAnalysis *climbing = [_altitude stepSpace];
        _ascending  = [[climbing clippingToLower:0 upper:(+INFINITY)] stairCase];
        _descending = [[climbing clippingToLower:(-INFINITY) upper:0] stairCase];
        
        HKUnit *heartRateUnit = [self _heartRateUnit];
        NSUInteger heartRateCount = quantities.count;
        double *heartRates = malloc(heartRateCount * sizeof(double));
        NSTimeInterval *heartStamps = malloc(heartRateCount * sizeof(NSTimeInterval));
        [quantities enumerateObjectsUsingBlock:^(HKDiscreteQuantitySample *quantity, NSUInteger idx, BOOL *stop) {
            heartRates[idx] = [quantity.quantity doubleValueForUnit:heartRateUnit];
            heartStamps[idx] = quantity.startDate.timeIntervalSinceReferenceDate;
        }];
        
        NSTimeInterval *heartIndx = malloc(heartRateCount * sizeof(NSTimeInterval));
        vDSP_vsaddD(heartStamps, 1, &timeOffset, heartIndx, 1, heartRateCount);
        
        _heartRate = [[WSDataAnalysis alloc] initWithData:heartRates keys:heartIndx domain:timeDomainLength length:heartRateCount];
        
        free(distances);
        free(altitudes);
        free(coordinates);
        free(locationStamps);
        free(locationIndx);
        free(heartRates);
        free(heartStamps);
        free(heartIndx);
    }
    return self;
}

- (instancetype)initWithDomain:(WSAnalysisDomain *)domain key:(WSDomainKey)key {
    if (self = [super init]) {
        WSDataAnalysis *domainData = [domain dataForKey:key];
        
        double domainLength = [domainData deltaOverRange:domain.fullRange];
        
        _domainKey = key;
        _fullRange = NSMakeRange(0, ceil(domainLength));
        
        _time = [domain.time convertToDomain:domainData];
        
        _distance = [domain.distance convertToDomain:domainData];
        _altitude = [domain.altitude convertToDomain:domainData];
        _coordinate = [domain.coordinate convertToDomain:domainData];
        _globeMap = [_coordinate globeMapForAltitudes:_altitude];
        
        _speed = [_distance derivativeInDomain:_time];
        _grade = [_altitude derivative];
        
        WSDataAnalysis *climbing = [_altitude stepSpace];
        _ascending  = [[climbing clippingToLower:0 upper:(+INFINITY)] stairCase];
        _descending = [[climbing clippingToLower:(-INFINITY) upper:0] stairCase];
        
        _heartRate = [domain.heartRate convertToDomain:domainData];
    }
    return self;
}

- (NSUInteger)indexForPercent:(double)percent {
    if (percent < 0) {
        return 0;
    }
    
    NSUInteger const maxIndx = NSRangeMaxIndex(self.fullRange);
    if (percent > 1) {
        return maxIndx;
    }
    return maxIndx * percent;
}

- (WSDataAnalysis *)dataForKey:(WSDomainKey)key {
    switch (key) {
        case WSDomainKeyTime:
            return self.time;
        case WSDomainKeyDistance:
            return self.distance;
        case WSDomainKeyClimbing:
            return self.ascending;
        default:
            return nil;
    }
}

- (NSUInteger)indexFromIndex:(NSUInteger)index inDomain:(WSAnalysisDomain *)domain {
    WSDomainKey const domainKey = self.domainKey;
    
    WSDataAnalysis *receiverInDomain = [self dataForKey:domainKey];
    WSDataAnalysis *parameterInDomain = [domain dataForKey:domainKey];
    
    double offset = [parameterInDomain datumAtIndex:index];
    double base = [receiverInDomain datumAtIndex:0];
    // assuming receiverInDomain.dx == 1
    offset -= base;
    
    NSUInteger ret = round(offset);
    return MAX(0, MIN(ret, NSRangeMaxIndex(self.fullRange)));
}

- (NSRange)rangeFromRange:(NSRange)range inDomain:(WSAnalysisDomain *)domain {
    return NSRangeMakeInclusive([self indexFromIndex:range.location inDomain:domain],
                                [self indexFromIndex:NSRangeMaxIndex(range) inDomain:domain]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; domainKey = %@; fullRange = %@>",
            [self class], self, NSStringFromWSDomainKey(self.domainKey), NSStringFromRange(self.fullRange)];
}

@end
