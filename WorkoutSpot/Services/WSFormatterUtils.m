//
//  WSFormatterUtils.m
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSFormatterUtils.h"

@implementation WSFormatterUtils

// MARK: - Contracted formatters

+ (NSString *)contractedSeconds:(NSTimeInterval)seconds {
    static NSDateComponentsFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateComponentsFormatter new];
        formatter.calendar = NSCalendar.autoupdatingCurrentCalendar;
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
    });
    return [formatter stringFromTimeInterval:seconds];
}

// MARK: - Abbreviated formatters

+ (NSMeasurementFormatter *)_cachedLengthSpeedAbbreviatedFormatter {
    static NSMeasurementFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSMeasurementFormatter new];
        formatter.locale = NSLocale.autoupdatingCurrentLocale;
        formatter.unitStyle = NSFormattingUnitStyleMedium;
        formatter.unitOptions = NSMeasurementFormatterUnitOptionsNaturalScale;
        formatter.numberFormatter.maximumFractionDigits = 2;
        formatter.numberFormatter.minimumFractionDigits = 2;
    });
    return formatter;
}

+ (NSString *)abbreviatedMeters:(double)meters {
    NSMeasurementFormatter *formatter = [self _cachedLengthSpeedAbbreviatedFormatter];
    NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:meters unit:[NSUnitLength meters]];
    return [formatter stringFromMeasurement:measurement];
}

+ (NSString *)abbreviatedMetersPerSecond:(double)mps {
    NSMeasurementFormatter *formatter = [self _cachedLengthSpeedAbbreviatedFormatter];
    NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:mps unit:[NSUnitSpeed metersPerSecond]];
    return [formatter stringFromMeasurement:measurement];
}

+ (NSString *)abbreviatedSeconds:(NSTimeInterval)seconds {
    static NSDateComponentsFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateComponentsFormatter new];
        formatter.calendar = NSCalendar.autoupdatingCurrentCalendar;
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
    });
    return [formatter stringFromTimeInterval:seconds];
}

// MARK: - Expanded formatters

+ (NSMeasurementFormatter *)_cachedLengthSpeedExpandedFormatter {
    static NSMeasurementFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSMeasurementFormatter new];
        formatter.locale = NSLocale.autoupdatingCurrentLocale;
        formatter.unitOptions = NSMeasurementFormatterUnitOptionsNaturalScale;
        formatter.unitStyle = NSFormattingUnitStyleLong;
        formatter.numberFormatter.maximumFractionDigits = 2;
        formatter.numberFormatter.minimumFractionDigits = 2;
    });
    return formatter;
}

+ (NSString *)expandedMeters:(double)meters {
    NSMeasurementFormatter *formatter = [self _cachedLengthSpeedExpandedFormatter];
    NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:meters unit:[NSUnitLength meters]];
    return [formatter stringFromMeasurement:measurement];
}

+ (NSString *)expandedMetersPerSecond:(double)mps {
    NSMeasurementFormatter *formatter = [self _cachedLengthSpeedExpandedFormatter];
    NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue:mps unit:[NSUnitSpeed metersPerSecond]];
    return [formatter stringFromMeasurement:measurement];
}

+ (NSString *)expandedSeconds:(NSTimeInterval)seconds {
    static NSDateComponentsFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateComponentsFormatter new];
        formatter.calendar = NSCalendar.autoupdatingCurrentCalendar;
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    });
    return [formatter stringFromTimeInterval:seconds];
}


// MARK: - Number formatters

+ (NSString *)beatsPerMinute:(double)bps {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSTimeInterval const secondsPerMinute = 60;
        
        formatter = [NSNumberFormatter new];
        formatter.locale = NSLocale.autoupdatingCurrentLocale;
        formatter.maximumFractionDigits = 0;
        formatter.multiplier = @(secondsPerMinute);
    });
    NSNumber *number = [NSNumber numberWithDouble:bps];
    return [formatter stringFromNumber:number];
}

+ (NSString *)percentage:(double)percentage {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterPercentStyle;
        formatter.locale = NSLocale.autoupdatingCurrentLocale;
        formatter.maximumFractionDigits = 2;
        formatter.minimumFractionDigits = 2;
    });
    NSNumber *number = [NSNumber numberWithDouble:percentage];
    return [formatter stringFromNumber:number];
}

// MARK: - Date formatters

+ (NSString *)timeOnlyFromDate:(NSDate *)date {
    static NSDateFormatter *timeOnly;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeOnly = [NSDateFormatter new];
        timeOnly.timeStyle = NSDateFormatterMediumStyle;
        timeOnly.timeZone = NSTimeZone.localTimeZone;
        timeOnly.locale = NSLocale.autoupdatingCurrentLocale;
        timeOnly.calendar = NSCalendar.autoupdatingCurrentCalendar;
        timeOnly.formattingContext = NSFormattingContextListItem;
    });
    return [timeOnly stringFromDate:date];
}
+ (NSString *)dateOnlyFromDate:(NSDate *)date {
    static NSDateFormatter *dateOnly;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateOnly = [NSDateFormatter new];
        dateOnly.dateStyle = NSDateFormatterLongStyle;
        dateOnly.timeZone = NSTimeZone.localTimeZone;
        dateOnly.locale = NSLocale.autoupdatingCurrentLocale;
        dateOnly.calendar = NSCalendar.autoupdatingCurrentCalendar;
        dateOnly.formattingContext = NSFormattingContextListItem;
    });
    return [dateOnly stringFromDate:date];
}
+ (NSString *)timeDateFromDate:(NSDate *)date {
    static NSDateFormatter *timeDate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeDate = [NSDateFormatter new];
        timeDate.timeStyle = NSDateFormatterShortStyle;
        timeDate.dateStyle = NSDateFormatterShortStyle;
        timeDate.timeZone = NSTimeZone.localTimeZone;
        timeDate.locale = NSLocale.autoupdatingCurrentLocale;
        timeDate.calendar = NSCalendar.autoupdatingCurrentCalendar;
        timeDate.formattingContext = NSFormattingContextListItem;
    });
    return [timeDate stringFromDate:date];
}

@end
