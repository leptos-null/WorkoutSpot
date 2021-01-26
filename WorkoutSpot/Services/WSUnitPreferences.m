//
//  WSUnitPreferences.m
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "WSUnitPreferences.h"

NSNotificationName const WSUnitPreferencesDidChangeNotification = @"WSUnitPreferencesDidChangeNotification";

NSString *const WSUnitPreferencesDistanceKey = @"WSUnitPreferencesDistanceKey";
NSString *const WSUnitPreferencesAltitudeKey = @"WSUnitPreferencesAltitudeKey";
NSString *const WSUnitPreferencesSpeedKey = @"WSUnitPreferencesSpeedKey";

@implementation WSUnitPreferences {
    NSUserDefaults *_userDefaults;
}

+ (WSUnitPreferences *)shared {
    static WSUnitPreferences *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSUnitLength *distanceUnit = [self _loadArchivedClass:[NSUnitLength class] forKey:WSUnitPreferencesDistanceKey];
        NSUnitLength *altitudeUnit = [self _loadArchivedClass:[NSUnitLength class] forKey:WSUnitPreferencesAltitudeKey];
        NSUnitSpeed *speedUnit = [self _loadArchivedClass:[NSUnitSpeed class] forKey:WSUnitPreferencesSpeedKey];
        
        BOOL usesMetricSystem = NSLocale.currentLocale.usesMetricSystem;
        
        _distanceUnit = distanceUnit ?: (usesMetricSystem ? [NSUnitLength kilometers] : [NSUnitLength miles]);
        _altitudeUnit = altitudeUnit ?: (usesMetricSystem ? [NSUnitLength meters] : [NSUnitLength feet]);
        _speedUnit = speedUnit ?: (usesMetricSystem ? [NSUnitSpeed kilometersPerHour] : [NSUnitSpeed milesPerHour]);
    }
    return self;
}

- (id)_loadArchivedClass:(Class)class forKey:(NSString *)key {
    // `dataForKey:` checks that the object is NSData before returning it, returns nil otherwise
    NSData *data = [_userDefaults dataForKey:key];
    if (data == nil) {
        return nil;
    }
    NSError *error = nil;
    id<NSSecureCoding> obj = [NSKeyedUnarchiver unarchivedObjectOfClass:class fromData:data error:&error];
    if (error != nil) {
        NSLog(@"Unarchiving: %@", error);
    }
    return obj;
}

- (void)_storeArchivedObject:(id<NSSecureCoding>)obj forKey:(NSString *)key {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:YES error:&error];
    if (error != nil) {
        NSLog(@"Archiving: %@", error);
    } else {
        [_userDefaults setObject:data forKey:key];
    }
}

- (void)_postDidChangeNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:WSUnitPreferencesDidChangeNotification object:self];
}

- (void)setDistanceUnit:(NSUnitLength *)distanceUnit {
    NSParameterAssert([distanceUnit isKindOfClass:[NSUnitLength class]]);
    _distanceUnit = distanceUnit;
    
    [self _storeArchivedObject:distanceUnit forKey:WSUnitPreferencesDistanceKey];
    [self _postDidChangeNotification];
}
- (void)setAltitudeUnit:(NSUnitLength *)altitudeUnit {
    NSParameterAssert([altitudeUnit isKindOfClass:[NSUnitLength class]]);
    _altitudeUnit = altitudeUnit;
    
    [self _storeArchivedObject:altitudeUnit forKey:WSUnitPreferencesAltitudeKey];
    [self _postDidChangeNotification];
}
- (void)setSpeedUnit:(NSUnitSpeed *)speedUnit {
    NSParameterAssert([speedUnit isKindOfClass:[NSUnitSpeed class]]);
    _speedUnit = speedUnit;
    
    [self _storeArchivedObject:speedUnit forKey:WSUnitPreferencesSpeedKey];
    [self _postDidChangeNotification];
}

- (__kindof NSUnit *)unitForType:(WSMeasurementType)type {
    switch (type) {
        case WSMeasurementTypeDistance:
            return self.distanceUnit;
        case WSMeasurementTypeAltitude:
            return self.altitudeUnit;
        case WSMeasurementTypeSpeed:
            return self.speedUnit;
        default:
            return nil;
    }
}
- (void)setUnit:(__kindof NSUnit *)unit forType:(WSMeasurementType)type {
    switch (type) {
        case WSMeasurementTypeDistance:
            self.distanceUnit = unit;
            break;
        case WSMeasurementTypeAltitude:
            self.altitudeUnit = unit;
            break;
        case WSMeasurementTypeSpeed:
            self.speedUnit = unit;
            break;
        default:
            break;
    }
}

@end


@implementation WSFormatterUtils (WSUnitPreferences)

+ (NSString *)abbreviatedDistance:(double)meters {
    return [self abbreviatedMeters:meters unit:WSUnitPreferences.shared.distanceUnit];
}
+ (NSString *)abbreviatedAltitude:(double)meters {
    return [self abbreviatedMeters:meters unit:WSUnitPreferences.shared.altitudeUnit];
}
+ (NSString *)abbreviatedSpeed:(double)mps {
    return [self abbreviatedMetersPerSecond:mps unit:WSUnitPreferences.shared.speedUnit];
}

+ (NSString *)expandedDistance:(double)meters {
    return [self expandedMeters:meters unit:WSUnitPreferences.shared.distanceUnit];
}
+ (NSString *)expandedAltitude:(double)meters {
    return [self expandedMeters:meters unit:WSUnitPreferences.shared.altitudeUnit];
}
+ (NSString *)expandedSpeed:(double)mps {
    return [self expandedMetersPerSecond:mps unit:WSUnitPreferences.shared.speedUnit];
}

@end
