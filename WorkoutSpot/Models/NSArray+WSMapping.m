//
//  NSArray+WSMapping.m
//  WorkoutSpot
//
//  Created by Leptos on 7/29/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "NSArray+WSMapping.h"

@implementation NSArray (WSMapping)

- (NSArray *)map:(id(^)(id))transform {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ret[idx] = transform(obj);
    }];
    return [ret copy];
}

- (NSArray *)compactMap:(id(^)(id))transform {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        const id val = transform(obj);
        if (val) {
            [ret addObject:val];
        }
    }];
    return [ret copy];
}

@end
