//
//  WSUnitPreferences.h
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSFormatterUtils.h"

@interface WSUnitPreferences : NSObject

@property (class, strong, nonatomic, readonly) WSUnitPreferences *shared;

/// Lateral distance unit
@property (strong, nonatomic) NSUnitLength *distanceUnit;
/// Vertical distance unit
@property (strong, nonatomic) NSUnitLength *altitudeUnit;
/// Speed unit
@property (strong, nonatomic) NSUnitSpeed *speedUnit;

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
