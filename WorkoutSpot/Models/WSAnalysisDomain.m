//
//  WSAnalysisDomain.m
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSAnalysisDomain.h"

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
                               heartSamples:(NSArray<WSStampedQuantity *> *)quantities
                                  startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    if (self = [super init]) {
        NSUInteger locationCount = locations.count;
        
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
        
        _domainKey = @selector(time);
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
        [quantities enumerateObjectsUsingBlock:^(WSStampedQuantity *quantity, NSUInteger idx, BOOL *stop) {
            heartRates[idx] = [quantity.quantity doubleValueForUnit:heartRateUnit];
            heartStamps[idx] = quantity.dateInterval.startDate.timeIntervalSinceReferenceDate;
        }];
        
        NSTimeInterval *heartIndx = malloc(locationCount * sizeof(NSTimeInterval));
        vDSP_vsaddD(heartStamps, 1, &timeOffset, heartIndx, 1, locationCount);
        
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

- (instancetype)initWithDomain:(WSAnalysisDomain *)domain key:(SEL)key {
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

- (WSDataAnalysis *)dataForKey:(SEL)key {
    WSDataAnalysis *(*resolver)(WSAnalysisDomain *self, SEL _cmd) = (void *)[self methodForSelector:key];
    return resolver(self, key);
}

- (NSUInteger)indexFromIndex:(NSUInteger)index inDomain:(WSAnalysisDomain *)domain {
    SEL domainSEL = self.domainKey;
    
    WSDataAnalysis *receiverInDomain = [self dataForKey:domainSEL];
    WSDataAnalysis *parameterInDomain = [domain dataForKey:domainSEL];
    
    double offset = [parameterInDomain datumAtIndex:index];
    double base = [receiverInDomain datumAtIndex:0];
    // assuming receiverInDomain.dx == 1
    offset -= base;
    
    return fmax(0, fmin(round(offset), NSRangeMaxIndex(self.fullRange)));
}

- (NSRange)rangeFromRange:(NSRange)range inDomain:(WSAnalysisDomain *)domain {
    return NSRangeMakeInclusive([self indexFromIndex:range.location inDomain:domain],
                                [self indexFromIndex:NSRangeMaxIndex(range) inDomain:domain]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; domainKey = %@; fullRange = %@>",
            [self class], self, NSStringFromSelector(self.domainKey), NSStringFromRange(self.fullRange)];
}

@end
