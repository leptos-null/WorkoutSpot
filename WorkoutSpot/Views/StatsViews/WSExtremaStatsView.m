//
//  WSExtremaStatsView.m
//  WorkoutSpot
//
//  Created by Leptos on 8/17/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSExtremaStatsView.h"
#import "../../Models/UIColor+WSColors.h"
#import "../../Services/WSFormatterUtils.h"

typedef NS_ENUM(NSUInteger, WSExtremaStatsLabelIndex) {
    WSExtremaStatsLabelIndexAltitude,
    WSExtremaStatsLabelIndexSpeed,
    WSExtremaStatsLabelIndexHeartRate,
    
    WSPointStatsLabelCaseCount
};

@implementation WSExtremaStatsView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        for (UIView *arrangedSubview in self.arrangedSubviews) {
            [arrangedSubview removeFromSuperview];
        }
        
        // must be set in order
        self.altitudeLabel = [UILabel new];
        self.speedLabel = [UILabel new];
        self.heartRateLabel = [UILabel new];
    }
    return self;
}

- (void)setExtremumType:(WSExtremaType)extremumType {
    _extremumType = extremumType;
    
    NSString *extremaType = nil;
    switch (extremumType) {
        case WSExtremaTypeMin: {
            extremaType = @"Min";
        } break;
            
        case WSExtremaTypeMax: {
            extremaType = @"Max";
        } break;
            
        default:
            break;
    }
    
    self.altitudeLabel.accessibilityLabel = [extremaType stringByAppendingString:@" altitude"];
    self.speedLabel.accessibilityLabel = [extremaType stringByAppendingString:@" speed"];
    self.heartRateLabel.accessibilityLabel = [extremaType stringByAppendingString:@" heart rate"];
    
    [self _updateLabelValues];
}

- (void)setStats:(WSSegmentStatistics *)stats {
    _stats = stats;
    
    [self _updateLabelValues];
}

- (void)_updateLabelValues {
    WSSegmentStatistics *stats = self.stats;
    
    CLLocationDistance altitude = 0;
    CLLocationSpeed speed = 0;
    WSHeartRate heartRate = 0;
    switch (self.extremumType) {
        case WSExtremaTypeMin: {
            altitude = stats.minimumAltitude;
            speed = stats.minimumSpeed;
            heartRate = stats.minimumHeartRate;
        } break;
            
        case WSExtremaTypeMax: {
            altitude = stats.maximumAltitude;
            speed = stats.maximumSpeed;
            heartRate = stats.maximumHeartRate;
        } break;
            
        default:
            break;
    }
    
    self.altitudeLabel.text = [WSFormatterUtils abbreviatedMeters:altitude];
    self.altitudeLabel.accessibilityValue = [WSFormatterUtils expandedMeters:altitude];
    self.altitudeLabel.hidden = (stats.analysisDomain.altitude == nil);
    
    self.speedLabel.text = [WSFormatterUtils abbreviatedMetersPerSecond:speed];
    self.speedLabel.accessibilityValue = [WSFormatterUtils expandedMetersPerSecond:speed];
    self.speedLabel.hidden = (stats.analysisDomain.speed == nil);
    
    self.heartRateLabel.text = [[WSFormatterUtils beatsPerMinute:heartRate] stringByAppendingString:@" BPM"];
    self.heartRateLabel.accessibilityValue = [[WSFormatterUtils beatsPerMinute:heartRate] stringByAppendingString:@" BPM"];
    self.heartRateLabel.hidden = (stats.analysisDomain.heartRate == nil);
}

- (void)_setGenericLabelProperties:(UILabel *)label {
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1 compatibleWithTraitCollection:self.traitCollection];
    label.adjustsFontForContentSizeCategory = YES;
}

// MARK: - UI Setters

- (void)setAltitudeLabel:(UILabel *)altitudeLabel {
    [self.altitudeLabel removeFromSuperview];
    
    _altitudeLabel = altitudeLabel;
    altitudeLabel.textColor = UIColor.altitudeColor;
    [self _setGenericLabelProperties:altitudeLabel];
    
    [self insertArrangedSubview:altitudeLabel atIndex:WSExtremaStatsLabelIndexAltitude];
}
- (void)setSpeedLabel:(UILabel *)speedLabel {
    [self.speedLabel removeFromSuperview];
    
    _speedLabel = speedLabel;
    speedLabel.textColor = UIColor.speedColor;
    [self _setGenericLabelProperties:speedLabel];
    
    [self insertArrangedSubview:speedLabel atIndex:WSExtremaStatsLabelIndexSpeed];
}
- (void)setHeartRateLabel:(UILabel *)heartRateLabel {
    [self.heartRateLabel removeFromSuperview];
    
    _heartRateLabel = heartRateLabel;
    heartRateLabel.textColor = UIColor.heartRateColor;
    [self _setGenericLabelProperties:heartRateLabel];
    
    [self insertArrangedSubview:heartRateLabel atIndex:WSExtremaStatsLabelIndexHeartRate];
}

@end
