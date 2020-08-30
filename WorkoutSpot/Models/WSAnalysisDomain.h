//
//  WSAnalysisDomain.h
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <HealthKit/HealthKit.h>

#import "WSDataAnalysis.h"
#import "WSCoordinateAnalysis.h"

typedef NS_ENUM(NSUInteger, WSDomainKey) {
    WSDomainKeyTime,
    WSDomainKeyDistance,
    WSDomainKeyClimbing,
    
    WSDomainKeyCaseCount
};

NSString *NSStringFromWSDomainKey(WSDomainKey key);

/// Beats per second
typedef double WSHeartRate;

/// @note Taking the average of a derivative in a domain that
/// the derivative was not with respect to results in skewed values
@interface WSAnalysisDomain : NSObject

/// Create a new analysis domain in @c WSDomainKeyTime
- (instancetype)initTimeDomainWithLocations:(NSArray<CLLocation *> *)locations
                               heartSamples:(NSArray<HKDiscreteQuantitySample *> *)quantities
                                  startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

/// @param domain Existing data to create a new analysis from
/// @param key The domain to map @c domain into
/// @return A new analysis domain in @c key with
///   data points interpolated from @c domain
- (instancetype)initWithDomain:(WSAnalysisDomain *)domain key:(WSDomainKey)key;

/// The data that describes the domain for the receiver.
@property (nonatomic, readonly) WSDomainKey domainKey;
/// The range representing all the data of the receiver
@property (nonatomic, readonly) NSRange fullRange;
/// @c NSTimeInterval since reference date
@property (strong, nonatomic, readonly) WSDataAnalysis *time;
/// @c CLLocationDistance traveled from the start point.
/// @discussion The distance is calculated along the route.
///   A route that consists of five laps around a 250 meter
///   track would read 750 meters at the conclusion of the 3rd lap.
@property (strong, nonatomic, readonly) WSDataAnalysis *distance;
/// @c CLLocationDistance above sea level
@property (strong, nonatomic, readonly) WSDataAnalysis *altitude;
@property (strong, nonatomic, readonly) WSCoordinateAnalysis *coordinate;
/// @c xyz coordinates over the globe
@property (strong, nonatomic, readonly) WSPointCloud *globeMap;
/// @c CLLocationSpeed
@property (strong, nonatomic, readonly) WSDataAnalysis *speed;
/// A percentage of the relationship between horizontal and vertical distance
/// @discussion Flat is 0%, while a 45º climb is 100% (represented as 1)
@property (strong, nonatomic, readonly) WSDataAnalysis *grade;

/// @c CLLocationDistance ascended
/// @discussion For a loop with a low point of 10 meters, and
///   a high points of 30 meters, @c ascending would increase
///   by @c 20 meters for each loop, while @c altitude would
///   fluctuate between @c 10 and @c 30 meters.
/// @note These values should always be postive
@property (strong, nonatomic, readonly) WSDataAnalysis *ascending;
/// @c CLLocationDistance descended
/// @discussion For a loop with a low point of 10 meters, and
///   a high points of 30 meters, @c descending would increase
///   by @c 20 meters for each loop, while @c altitude would
///   fluctuate between @c 10 and @c 30 meters
/// @note These values should always be negative
@property (strong, nonatomic, readonly) WSDataAnalysis *descending;
/// @c WSHeartRate
@property (strong, nonatomic, readonly) WSDataAnalysis *heartRate;

/// @param percent A value [0, 1] that
/// represents a portion of the domain
- (NSUInteger)indexForPercent:(double)percent;
/// Finds the index of @c domain[index] for the receiver
- (NSUInteger)indexFromIndex:(NSUInteger)index inDomain:(WSAnalysisDomain *)domain;
- (NSRange)rangeFromRange:(NSRange)range inDomain:(WSAnalysisDomain *)domain;

@end
