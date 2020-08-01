//
//  NSArray+WSMapping.h
//  WorkoutSpot
//
//  Created by Leptos on 7/29/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<__covariant ObjectType> (WSMapping)

- (NSArray *)map:(id(^)(ObjectType obj))transform;
- (NSArray *)compactMap:(id(^)(ObjectType obj))transform;

@end
