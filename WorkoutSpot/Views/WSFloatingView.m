//
//  WSFloatingView.m
//  WorkoutSpot
//
//  Created by Leptos on 8/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSFloatingView.h"

@implementation WSFloatingView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.layer.cornerCurve = kCACornerCurveContinuous;
    }
    return self;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    self.layer.cornerRadius = bounds.size.width/18;
}

@end
