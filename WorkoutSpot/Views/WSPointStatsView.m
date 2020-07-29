//
//  WSPointStatsView.m
//  WorkoutSpot
//
//  Created by Leptos on 7/27/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSPointStatsView.h"
#import "../Models/UIColor+WSColors.h"
#import "../Services/WSFormatterUtils.h"

typedef NS_ENUM(NSUInteger, WSPointStatsLabelIndex) {
    WSPointStatsLabelIndexTime,
    WSPointStatsLabelIndexDistance,
    WSPointStatsLabelIndexAltitude,
    WSPointStatsLabelIndexGrade,
    WSPointStatsLabelIndexSpeed,
    WSPointStatsLabelIndexHeartRate,
    
    WSPointStatsLabelCaseCount
};

@implementation WSPointStatsView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        for (UIView *arrangedSubview in self.arrangedSubviews) {
            [arrangedSubview removeFromSuperview];
        }
        
        self.timeLabel = [UILabel new];
        self.distanceLabel = [UILabel new];
        self.altitudeLabel = [UILabel new];
        self.gradeLabel = [UILabel new];
        self.speedLabel = [UILabel new];
        self.heartRateLabel = [UILabel new];
    }
    return self;
}

- (void)setStats:(WSPointStatistics *)stats {
    _stats = stats;
    
    NSDate *date = stats.date;
    self.timeLabel.text = [@"Time: " stringByAppendingString:[WSFormatterUtils timeOnlyFromDate:date]];
    self.timeLabel.accessibilityLabel = [@"Time: " stringByAppendingString:[WSFormatterUtils timeOnlyFromDate:date]];
    self.timeLabel.hidden = (stats.analysisDomain.time == nil);
    
    CLLocationDistance dist = stats.distance;
    self.distanceLabel.text = [@"Distance: " stringByAppendingString:[WSFormatterUtils abbreviatedMeters:dist]];
    self.distanceLabel.accessibilityLabel = [@"Distance: " stringByAppendingString:[WSFormatterUtils expandedMeters:dist]];
    self.distanceLabel.hidden = (stats.analysisDomain.distance == nil);
    
    CLLocationDistance altitude = stats.altitude;
    self.altitudeLabel.text = [@"Altitude: " stringByAppendingString:[WSFormatterUtils abbreviatedMeters:altitude]];
    self.altitudeLabel.accessibilityLabel = [@"Altitude: " stringByAppendingString:[WSFormatterUtils expandedMeters:altitude]];
    self.altitudeLabel.hidden = (stats.analysisDomain.altitude == nil);
    
    double grade = stats.grade;
    self.gradeLabel.text = [@"Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.accessibilityLabel = [@"Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.hidden = (stats.analysisDomain.grade == nil);
    
    CLLocationSpeed speed = stats.speed;
    self.speedLabel.text = [@"Speed: " stringByAppendingString:[WSFormatterUtils abbreviatedMetersPerSecond:speed]];
    self.speedLabel.accessibilityLabel = [@"Speed: " stringByAppendingString:[WSFormatterUtils expandedMetersPerSecond:speed]];
    self.speedLabel.hidden = (stats.analysisDomain.speed == nil);
    
    WSHeartRate heartRate = stats.heartRate;
    self.heartRateLabel.text = [NSString stringWithFormat:@"Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.accessibilityLabel = [NSString stringWithFormat:@"Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.hidden = (stats.analysisDomain.heartRate == nil);
}

- (void)_setGenericLabelProperties:(UILabel *)label {
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    label.adjustsFontForContentSizeCategory = YES;
    label.textAlignment = NSTextAlignmentLeft;
}

// MARK: - UI Setters

- (void)setTimeLabel:(UILabel *)timeLabel {
    [self.timeLabel removeFromSuperview];
    
    _timeLabel = timeLabel;
    timeLabel.textColor = UIColor.labelColor;
    [self _setGenericLabelProperties:timeLabel];
    
    [self insertArrangedSubview:timeLabel atIndex:WSPointStatsLabelIndexTime];
}
- (void)setDistanceLabel:(UILabel *)distanceLabel {
    [self.distanceLabel removeFromSuperview];
    
    _distanceLabel = distanceLabel;
    distanceLabel.textColor = UIColor.labelColor;
    [self _setGenericLabelProperties:distanceLabel];
    
    [self insertArrangedSubview:distanceLabel atIndex:WSPointStatsLabelIndexDistance];
}
- (void)setAltitudeLabel:(UILabel *)altitudeLabel {
    [self.altitudeLabel removeFromSuperview];
    
    _altitudeLabel = altitudeLabel;
    altitudeLabel.textColor = UIColor.altitudeColor;
    [self _setGenericLabelProperties:altitudeLabel];
    
    [self insertArrangedSubview:altitudeLabel atIndex:WSPointStatsLabelIndexAltitude];
}
- (void)setGradeLabel:(UILabel *)gradeLabel {
    [self.gradeLabel removeFromSuperview];
    
    _gradeLabel = gradeLabel;
    gradeLabel.textColor = UIColor.labelColor;
    [self _setGenericLabelProperties:gradeLabel];
    
    [self insertArrangedSubview:gradeLabel atIndex:WSPointStatsLabelIndexGrade];
}
- (void)setSpeedLabel:(UILabel *)speedLabel {
    [self.speedLabel removeFromSuperview];
    
    _speedLabel = speedLabel;
    speedLabel.textColor = UIColor.speedColor;
    [self _setGenericLabelProperties:speedLabel];
    
    [self insertArrangedSubview:speedLabel atIndex:WSPointStatsLabelIndexSpeed];
}
- (void)setHeartRateLabel:(UILabel *)heartRateLabel {
    [self.heartRateLabel removeFromSuperview];
    
    _heartRateLabel = heartRateLabel;
    heartRateLabel.textColor = UIColor.heartRateColor;
    [self _setGenericLabelProperties:heartRateLabel];
    
    [self insertArrangedSubview:heartRateLabel atIndex:WSPointStatsLabelIndexHeartRate];
}

@end
