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
    _distanceUnit = distanceUnit;
    
    [self _storeArchivedObject:distanceUnit forKey:WSUnitPreferencesDistanceKey];
    [self _postDidChangeNotification];
}
- (void)setAltitudeUnit:(NSUnitLength *)altitudeUnit {
    _altitudeUnit = altitudeUnit;
    
    [self _storeArchivedObject:altitudeUnit forKey:WSUnitPreferencesAltitudeKey];
    [self _postDidChangeNotification];
}
- (void)setSpeedUnit:(NSUnitSpeed *)speedUnit {
    _speedUnit = speedUnit;
    
    [self _storeArchivedObject:speedUnit forKey:WSUnitPreferencesSpeedKey];
    [self _postDidChangeNotification];
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
