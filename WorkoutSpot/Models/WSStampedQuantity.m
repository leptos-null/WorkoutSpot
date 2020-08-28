//
//  WSStampedQuantity.m
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSStampedQuantity.h"

@implementation WSStampedQuantity

- (instancetype)initWithQuantity:(HKQuantity *)quantity dateInterval:(NSDateInterval *)dateInterval {
    if (self = [super init]) {
        _quantity = quantity;
        _dateInterval = dateInterval;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; quantity = %@; dateInterval = %@>",
            [self class], self, self.quantity, self.dateInterval];
}

@end
