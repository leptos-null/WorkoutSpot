//
//  WSGraphConfiguration.m
//  WorkoutSpot
//
//  Created by Leptos on 9/12/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSGraphConfiguration.h"

@implementation WSGraphConfiguration

- (id)copyWithZone:(NSZone *)zone {
    WSGraphConfiguration *ret = [[WSGraphConfiguration allocWithZone:zone] init];
    ret.size = self.size;
    ret.edgeInsets = self.edgeInsets;
    ret.range = self.range;
    ret.smoothingTechnique = self.smoothingTechnique;
    return ret;
}

@end
