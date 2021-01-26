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
        NSUInteger const locationCount = locations.count;
        
        NSTimeInterval const timeStartOffset = startDate.timeIntervalSinceReferenceDate;
        NSTimeInterval const timeDomainLength = endDate.timeIntervalSinceReferenceDate - timeStartOffset;
        
        CLLocationDistance *altitudes = malloc(locationCount * sizeof(CLLocationDistance));
        CLLocationCoordinate2D *coordinates = malloc(locationCount * sizeof(CLLocationCoordinate2D));
        
        vDSP_Length altitudeLength = 0;
        vDSP_Length coordinateLength = 0;
        NSTimeInterval *altitudeIndx = malloc(locationCount * sizeof(NSTimeInterval));
        NSTimeInterval *coordinateIndx = malloc(locationCount * sizeof(NSTimeInterval));
        
        for (CLLocation *location in locations) {
            NSTimeInterval timeIndx = location.timestamp.timeIntervalSinceReferenceDate - timeStartOffset;
            
            CLLocationDistance altitude = location.altitude;
            CLLocationCoordinate2D coordinate = location.coordinate;
            
            // it wasn't clear if isfinite or !isnan should be used here
            if (location.verticalAccuracy >= 0 && isfinite(altitude)) {
                altitudes[altitudeLength] = altitude;
                altitudeIndx[altitudeLength] = timeIndx;
                altitudeLength++;
            }
            
            if (location.horizontalAccuracy >= 0 && CLLocationCoordinate2DIsValid(coordinate)) {
                coordinates[coordinateLength] = coordinate;
                coordinateIndx[coordinateLength] = timeIndx;
                coordinateLength++;
            }
        }
        
        NSUInteger const timeDomainRange = ceil(timeDomainLength);
        _domainKey = WSDomainKeyTime;
        _fullRange = NSMakeRange(0, timeDomainRange);
        
        double *linearTime = malloc(timeDomainRange * sizeof(double));
        double const identityScale = 1;
        vDSP_vrampD(&timeStartOffset, &identityScale, linearTime, 1, timeDomainRange); // linearTime[n] = timeStartOffset + n * identityScale
        
        _time = [[WSDataAnalysis alloc] initWithInterpolatedData:linearTime length:timeDomainRange];
        
        _altitude = [[WSDataAnalysis alloc] initWithData:altitudes keys:altitudeIndx domain:timeDomainLength length:altitudeLength];
        _coordinate = [[WSCoordinateAnalysis alloc] initWithCoordinates:coordinates keys:coordinateIndx domain:timeDomainLength length:coordinateLength];
        
        _globeMap = [_coordinate globeMapForAltitudes:_altitude];
        _distance = [[_coordinate stepSpace] stairCase];
        
        _speed = [_distance derivative];
        _grade = [_altitude derivativeInDomain:_distance];
        
        WSDataAnalysis *climbing = [_altitude stepSpace];
        _ascending  = [[climbing clippingToLower:0 upper:(+INFINITY)] stairCase];
        _descending = [[climbing clippingToLower:(-INFINITY) upper:0] stairCase];
        
        HKUnit *heartRateUnit = [self _heartRateUnit];
        
        NSUInteger const heartRateCount = quantities.count;
        double *heartRates = malloc(heartRateCount * sizeof(double));
        NSTimeInterval *heartIndx = malloc(heartRateCount * sizeof(NSTimeInterval));
        
        [quantities enumerateObjectsUsingBlock:^(HKDiscreteQuantitySample *quantity, NSUInteger idx, BOOL *stop) {
            heartRates[idx] = [quantity.quantity doubleValueForUnit:heartRateUnit];
            heartIndx[idx] = quantity.startDate.timeIntervalSinceReferenceDate - timeStartOffset;
        }];
        
        _heartRate = [[WSDataAnalysis alloc] initWithData:heartRates keys:heartIndx domain:timeDomainLength length:heartRateCount];
        
        free(altitudes);
        free(coordinates);
        free(altitudeIndx);
        free(coordinateIndx);
        free(heartRates);
        free(heartIndx);
    }
    return self;
}

- (instancetype)initWithDomain:(WSAnalysisDomain *)domain key:(WSDomainKey)key {
    if (self = [super init]) {
        WSDataAnalysis *domainData = [domain dataForDomainKey:key];
        if (domainData == nil) {
            return nil;
        }
        
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

- (WSDataAnalysis *)dataForDomainKey:(WSDomainKey)key {
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
    
    WSDataAnalysis *receiverInDomain = [self dataForDomainKey:domainKey];
    WSDataAnalysis *parameterInDomain = [domain dataForDomainKey:domainKey];
    
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
