//
//  WSPointStatsView.h
//  WorkoutSpot
//
//  Created by Leptos on 7/27/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../Models/WSPointStatistics.h"

@interface WSPointStatsView : UIStackView

@property (strong, nonatomic) WSPointStatistics *stats;

@property (strong, nonatomic, readonly) UILabel *timeLabel;
@property (strong, nonatomic, readonly) UILabel *distanceLabel;
@property (strong, nonatomic, readonly) UILabel *altitudeLabel;
@property (strong, nonatomic, readonly) UILabel *gradeLabel;
@property (strong, nonatomic, readonly) UILabel *speedLabel;
@property (strong, nonatomic, readonly) UILabel *heartRateLabel;

@end
