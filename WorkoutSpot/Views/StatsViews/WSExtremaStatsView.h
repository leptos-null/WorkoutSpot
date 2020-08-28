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

/// Display extrema over a segment
@interface WSExtremaStatsView : UIStackView
/// The segment to provide statistics for
@property (strong, nonatomic) WSSegmentStatistics *stats;
/// The extremum type to provide statistics for
@property (nonatomic) WSExtremaType extremumType;

/// The label providing altitude statistics
@property (strong, nonatomic, readonly) UILabel *altitudeLabel;
/// The label providing speed statistics
@property (strong, nonatomic, readonly) UILabel *speedLabel;
/// The label providing heart rate statistics
@property (strong, nonatomic, readonly) UILabel *heartRateLabel;

@end
