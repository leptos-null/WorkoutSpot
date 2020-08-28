//
//  WSStampedQuantity.h
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

/// A quantity with an associated date interval
@interface WSStampedQuantity : NSObject
/// Create a stamped quantity
- (instancetype)initWithQuantity:(HKQuantity *)quantity dateInterval:(NSDateInterval *)dateInterval;
/// The quantity that is relavent over @c dateInterval
@property (strong, nonatomic, readonly) HKQuantity *quantity;
/// The date interval for which @c quantity is relavent for
@property (strong, nonatomic, readonly) NSDateInterval *dateInterval;

@end
