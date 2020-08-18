//
//  WSSegmentStatsView.h
//  WorkoutSpot
//
//  Created by Leptos on 7/27/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../Models/WSSegmentStatistics.h"

@interface WSSegmentStatsView : UIStackView

@property (strong, nonatomic) WSSegmentStatistics *stats;

@property (strong, nonatomic, readonly) UILabel *durationLabel;
@property (strong, nonatomic, readonly) UILabel *distanceLabel;
@property (strong, nonatomic, readonly) UILabel *climbedLabel;
@property (strong, nonatomic, readonly) UILabel *gradeLabel;
@property (strong, nonatomic, readonly) UILabel *speedLabel;
@property (strong, nonatomic, readonly) UILabel *heartRateLabel;

@end
