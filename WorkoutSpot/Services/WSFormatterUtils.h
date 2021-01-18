//
//  WSFormatterUtils.h
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Convience methods to format values as localized strings.
@interface WSFormatterUtils : NSObject

/// @param seconds Time interval in seconds
/// @returns A string such as "8m 39s"
+ (NSString *)contractedSeconds:(NSTimeInterval)seconds;

/// @param meters Distance in meters
/// @returns A string such as "5,49 km", "3.41 mi", etc.
+ (NSString *)abbreviatedMeters:(double)meters unit:(NSUnitLength *)unit;
/// @param mps Speed in meters per second
/// @returns A string such as "5,49 km/h", "3.41 mph", etc.
+ (NSString *)abbreviatedMetersPerSecond:(double)mps unit:(NSUnitSpeed *)unit;
/// @param seconds Time interval in seconds
/// @returns A string such as "8 min, 39 sec"
+ (NSString *)abbreviatedSeconds:(NSTimeInterval)seconds;

/// @param meters Distance in meters
/// @returns A string such as "5,49 kilometers", "3.41 miles", etc.
+ (NSString *)expandedMeters:(double)meters unit:(NSUnitLength *)unit;
/// @param mps Speed in meters per second
/// @returns A string such as "5,49 kilometers per hour", "3.41 miles per hour", etc.
+ (NSString *)expandedMetersPerSecond:(double)mps unit:(NSUnitSpeed *)unit;
/// @param seconds Time interval in seconds
/// @returns A string such as "8 minutes, 39 seconds"
+ (NSString *)expandedSeconds:(NSTimeInterval)seconds;

/// @param bps Heart rate in beats per second
/// @returns A string such as "93" in beats per minute
+ (NSString *)beatsPerMinute:(double)bps;

/// @param percentage A value in [0, 1] range
/// @returns A string such as "8%"
+ (NSString *)percentage:(double)percentage;

/// @param date A date to represent
/// @returns A string such as "10:09:30 AM"
+ (NSString *)timeOnlyFromDate:(NSDate *)date;
/// @param date A date to represent
/// @returns A string such as "September 9, 2014"
+ (NSString *)dateOnlyFromDate:(NSDate *)date;
/// @param date A date to represent
/// @returns A string such as "9/9/14, 10:09 AM"
+ (NSString *)timeDateFromDate:(NSDate *)date;

@end
