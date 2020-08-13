//
//  HKObjectType+WSTypes.m
//  WorkoutSpot
//
//  Created by Leptos on 8/12/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "HKObjectType+WSTypes.h"

@implementation HKObjectType (WSTypes)

+ (HKQuantityType *)heartRateType {
    return [self quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
}

@end
