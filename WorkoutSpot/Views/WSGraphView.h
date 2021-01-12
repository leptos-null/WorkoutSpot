//
//  WSGraphView.h
//  WorkoutSpot
//
//  Created by Leptos on 6/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../Models/WSSegmentStatistics.h"

@interface WSGraphView : UIView

@property (strong, nonatomic) WSSegmentStatistics *segmentStats;
@property (nonatomic) UIEdgeInsets graphInsets;

@property (strong, nonatomic, readonly) WSGraphGuide *domainGuide;

@property (strong, nonatomic, readonly) WSGraphGuide *heartRateGraph;
@property (strong, nonatomic, readonly) WSGraphGuide *speedGraph;
@property (strong, nonatomic, readonly) WSGraphGuide *altitudeGraph;

@end
