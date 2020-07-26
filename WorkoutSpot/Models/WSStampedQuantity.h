//
//  WSStampedQuantity.h
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

@interface WSStampedQuantity : NSObject

- (instancetype)initWithQuantity:(HKQuantity *)quantity dateInterval:(NSDateInterval *)dateInterval;

@property (strong, nonatomic, readonly) HKQuantity *quantity;
@property (strong, nonatomic, readonly) NSDateInterval *dateInterval;

@end
