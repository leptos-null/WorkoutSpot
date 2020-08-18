//
//  WSSegmentStatsView.m
//  WorkoutSpot
//
//  Created by Leptos on 7/27/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSSegmentStatsView.h"
#import "../../Models/UIColor+WSColors.h"
#import "../../Services/WSFormatterUtils.h"

@implementation WSSegmentStatsView

typedef NS_ENUM(NSUInteger, WSSegmentStatsLabelIndex) {
    WSSegmentStatsLabelIndexDuration,
    WSSegmentStatsLabelIndexDistance,
    WSSegmentStatsLabelIndexClimbed,
    WSSegmentStatsLabelIndexGrade,
    WSSegmentStatsLabelIndexSpeed,
    WSSegmentStatsLabelIndexHeartRate,
    
    WSSegmentStatsLabelCaseCount
};

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        for (UIView *arrangedSubview in self.arrangedSubviews) {
            [arrangedSubview removeFromSuperview];
        }
        
        // must be set in order
        self.durationLabel = [UILabel new];
        self.distanceLabel = [UILabel new];
        self.climbedLabel = [UILabel new];
        self.gradeLabel = [UILabel new];
        self.speedLabel = [UILabel new];
        self.heartRateLabel = [UILabel new];
    }
    return self;
}

- (void)setStats:(WSSegmentStatistics *)stats {
    _stats = stats;
    
    NSTimeInterval deltaTime = stats.duration;
    self.durationLabel.text = [@"Duration: " stringByAppendingString:[WSFormatterUtils abbreviatedSeconds:deltaTime]];
    self.durationLabel.accessibilityLabel = [@"Duration: " stringByAppendingString:[WSFormatterUtils expandedSeconds:deltaTime]];
    self.durationLabel.hidden = (stats.analysisDomain.time == nil);
    
    CLLocationDistance dist = stats.deltaDistance;
    self.distanceLabel.text = [@"Distance: " stringByAppendingString:[WSFormatterUtils abbreviatedMeters:dist]];
    self.distanceLabel.accessibilityLabel = [@"Distance: " stringByAppendingString:[WSFormatterUtils expandedMeters:dist]];
    self.distanceLabel.hidden = (stats.analysisDomain.distance == nil);
    
    CLLocationDistance climbed = stats.ascending;
    self.climbedLabel.text = [@"Climbing: " stringByAppendingString:[WSFormatterUtils abbreviatedMeters:climbed]];
    self.climbedLabel.accessibilityLabel = [@"Climbing: " stringByAppendingString:[WSFormatterUtils expandedMeters:climbed]];
    self.climbedLabel.hidden = (stats.analysisDomain.ascending == nil);
    
    double grade = stats.averageGrade;
    self.gradeLabel.text = [@"Avg. Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.accessibilityLabel = [@"Average Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.hidden = (stats.analysisDomain.grade == nil);
    
    CLLocationSpeed speed = stats.averageSpeed;
    self.speedLabel.text = [@"Avg. Speed: " stringByAppendingString:[WSFormatterUtils abbreviatedMetersPerSecond:speed]];
    self.speedLabel.accessibilityLabel = [@"Average Speed: " stringByAppendingString:[WSFormatterUtils expandedMetersPerSecond:speed]];
    self.speedLabel.hidden = (stats.analysisDomain.speed == nil);
    
    WSHeartRate heartRate = stats.averageHeartRate;
    self.heartRateLabel.text = [NSString stringWithFormat:@"Avg. Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.accessibilityLabel = [NSString stringWithFormat:@"Average Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.hidden = (stats.analysisDomain.heartRate == nil);
}

- (void)_setGenericLabelProperties:(UILabel *)label {
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    label.adjustsFontForContentSizeCategory = YES;
    label.textAlignment = NSTextAlignmentRight;
    label.lineBreakMode = NSLineBreakByTruncatingHead;
}

// MARK: - UI Setters

- (void)setDurationLabel:(UILabel *)durationLabel {
    [self.durationLabel removeFromSuperview];
    
    _durationLabel = durationLabel;
    durationLabel.textColor = UIColor.segmentColor;
    [self _setGenericLabelProperties:durationLabel];
    
    [self insertArrangedSubview:durationLabel atIndex:WSSegmentStatsLabelIndexDuration];
}
- (void)setDistanceLabel:(UILabel *)distanceLabel {
    [self.distanceLabel removeFromSuperview];
    
    _distanceLabel = distanceLabel;
    distanceLabel.textColor = UIColor.segmentColor;
    [self _setGenericLabelProperties:distanceLabel];
    
    [self insertArrangedSubview:distanceLabel atIndex:WSSegmentStatsLabelIndexDistance];
}
- (void)setClimbedLabel:(UILabel *)climbedLabel {
    [self.climbedLabel removeFromSuperview];
    
    _climbedLabel = climbedLabel;
    climbedLabel.textColor = UIColor.altitudeColor;
    [self _setGenericLabelProperties:climbedLabel];
    
    [self insertArrangedSubview:climbedLabel atIndex:WSSegmentStatsLabelIndexClimbed];
}
- (void)setGradeLabel:(UILabel *)gradeLabel {
    [self.gradeLabel removeFromSuperview];
    
    _gradeLabel = gradeLabel;
    gradeLabel.textColor = UIColor.segmentColor;
    [self _setGenericLabelProperties:gradeLabel];
    
    [self insertArrangedSubview:gradeLabel atIndex:WSSegmentStatsLabelIndexGrade];
}
- (void)setSpeedLabel:(UILabel *)speedLabel {
    [self.speedLabel removeFromSuperview];
    
    _speedLabel = speedLabel;
    speedLabel.textColor = UIColor.speedColor;
    [self _setGenericLabelProperties:speedLabel];
    
    [self insertArrangedSubview:speedLabel atIndex:WSSegmentStatsLabelIndexSpeed];
}
- (void)setHeartRateLabel:(UILabel *)heartRateLabel {
    [self.heartRateLabel removeFromSuperview];
    
    _heartRateLabel = heartRateLabel;
    heartRateLabel.textColor = UIColor.heartRateColor;
    [self _setGenericLabelProperties:heartRateLabel];
    
    [self insertArrangedSubview:heartRateLabel atIndex:WSSegmentStatsLabelIndexHeartRate];
}

@end
