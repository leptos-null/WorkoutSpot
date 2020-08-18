//
//  WSExtremaStatsView.h
//  WorkoutSpot
//
//  Created by Leptos on 8/17/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../Models/WSSegmentStatistics.h"

typedef NS_ENUM(NSUInteger, WSExtremaType) {
    WSExtremaTypeMin,
    WSExtremaTypeMax,
    
    WSExtremaTypeCaseCount
};

@interface WSExtremaStatsView : UIStackView

@property (strong, nonatomic) WSSegmentStatistics *stats;

@property (nonatomic) WSExtremaType extremumType;

@property (strong, nonatomic, readonly) UILabel *altitudeLabel;
@property (strong, nonatomic, readonly) UILabel *speedLabel;
@property (strong, nonatomic, readonly) UILabel *heartRateLabel;

@end
