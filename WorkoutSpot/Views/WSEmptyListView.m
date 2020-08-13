//
//  WSEmptyListView.m
//  WorkoutSpot
//
//  Created by Leptos on 8/13/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSEmptyListView.h"

@implementation WSEmptyListView

+ (instancetype)fromNibWithOwner:(id)owner {
    NSArray *objs = [[NSBundle bundleForClass:self] loadNibNamed:@"EmptyList" owner:owner options:nil];
    for (id obj in objs) {
        if ([obj isKindOfClass:self]) {
            return obj;
        }
    }
    return nil;
}

@end
