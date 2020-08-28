//
//  HKObjectType+WSTypes.h
//  WorkoutSpot
//
//  Created by Leptos on 8/12/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <HealthKit/HealthKit.h>

@interface HKObjectType (WSTypes)

/// Returns the shared quantity type for heart rate
+ (HKQuantityType *)heartRateType;

@end
