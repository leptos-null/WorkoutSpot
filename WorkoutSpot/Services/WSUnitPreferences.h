//
//  WSUnitPreferences.h
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSFormatterUtils.h"

/// A notification that indicates a unit preference has changed.
OBJC_EXPORT NSNotificationName const WSUnitPreferencesDidChangeNotification;

typedef NS_ENUM(NSUInteger, WSMeasurementType) {
    /// Corresponds with the @c distanceUnit of @c WSUnitPreferences
    WSMeasurementTypeDistance,
    /// Corresponds with the @c altitudeUnit of @c WSUnitPreferences
    WSMeasurementTypeAltitude,
    /// Corresponds with the @c speedUnit of @c WSUnitPreferences
    WSMeasurementTypeSpeed,
    /// The count of @c WSMeasurementType cases; not a valid case
    WSMeasurementTypeCaseCount
};

@interface WSUnitPreferences : NSObject
/// The shared Unit Preferences instance.
/// Another instance should not be created.
@property (class, strong, nonatomic, readonly) WSUnitPreferences *shared;

/// Lateral distance unit
@property (strong, nonatomic) NSUnitLength *distanceUnit;
/// Vertical distance unit
@property (strong, nonatomic) NSUnitLength *altitudeUnit;
/// Speed unit
@property (strong, nonatomic) NSUnitSpeed *speedUnit;

- (__kindof NSUnit *)unitForType:(WSMeasurementType)type;
- (void)setUnit:(__kindof NSUnit *)unit forType:(WSMeasurementType)type;

@end


@interface WSFormatterUtils (WSUnitPreferences)

/// @param meters Distance in meters
/// @returns A string such as "5,49 km", "3.41 mi", etc.
+ (NSString *)abbreviatedDistance:(double)meters;
/// @param meters Altitude in meters
/// @returns A string such as "5,49 km", "3.41 mi", etc.
+ (NSString *)abbreviatedAltitude:(double)meters;
/// @param mps Speed in meters per second
/// @returns A string such as "5,49 km/h", "3.41 mph", etc.
+ (NSString *)abbreviatedSpeed:(double)mps;

/// @param meters Distance in meters
/// @returns A string such as "5,49 kilometers", "3.41 miles", etc.
+ (NSString *)expandedDistance:(double)meters;
/// @param meters Altitude in meters
/// @returns A string such as "5,49 kilometers", "3.41 miles", etc.
+ (NSString *)expandedAltitude:(double)meters;
/// @param mps Speed in meters per second
/// @returns A string such as "5,49 kilometers per hour", "3.41 miles per hour", etc.
+ (NSString *)expandedSpeed:(double)mps;

@end
