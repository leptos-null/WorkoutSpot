//
//  WSSegmentStatsView.m
//  WorkoutSpot
//
//  Created by Leptos on 7/27/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSSegmentStatsView.h"
#import "../../Models/UIColor+WSColors.h"
#import "../../Services/WSUnitPreferences.h"

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
        
        NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
        [defaultCenter addObserver:self selector:@selector(_updateStatsLabels) name:WSUnitPreferencesDidChangeNotification object:nil];
    }
    return self;
}

- (void)setStats:(WSSegmentStatistics *)stats {
    _stats = stats;
    
    [self _updateStatsLabels];
}

- (void)_updateStatsLabels {
    WSSegmentStatistics *stats = self.stats;
    
    NSTimeInterval deltaTime = stats.duration;
    self.durationLabel.text = [@"Duration: " stringByAppendingString:[WSFormatterUtils abbreviatedSeconds:deltaTime]];
    self.durationLabel.accessibilityLabel = [@"Duration: " stringByAppendingString:[WSFormatterUtils expandedSeconds:deltaTime]];
    self.durationLabel.hidden = (stats.analysisDomain.time == nil);
    
    CLLocationDistance dist = stats.deltaDistance;
    self.distanceLabel.text = [@"Distance: " stringByAppendingString:[WSFormatterUtils abbreviatedDistance:dist]];
    self.distanceLabel.accessibilityLabel = [@"Distance: " stringByAppendingString:[WSFormatterUtils expandedDistance:dist]];
    self.distanceLabel.hidden = (stats.analysisDomain.distance == nil);
    
    CLLocationDistance climbed = stats.ascending;
    self.climbedLabel.text = [@"Climbing: " stringByAppendingString:[WSFormatterUtils abbreviatedAltitude:climbed]];
    self.climbedLabel.accessibilityLabel = [@"Climbing: " stringByAppendingString:[WSFormatterUtils expandedAltitude:climbed]];
    self.climbedLabel.hidden = (stats.analysisDomain.ascending == nil);
    
    double grade = stats.averageGrade;
    self.gradeLabel.text = [@"Avg. Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.accessibilityLabel = [@"Average Grade: " stringByAppendingString:[WSFormatterUtils percentage:grade]];
    self.gradeLabel.hidden = (stats.analysisDomain.grade == nil);
    
    CLLocationSpeed speed = stats.averageSpeed;
    self.speedLabel.text = [@"Avg. Speed: " stringByAppendingString:[WSFormatterUtils abbreviatedSpeed:speed]];
    self.speedLabel.accessibilityLabel = [@"Average Speed: " stringByAppendingString:[WSFormatterUtils expandedSpeed:speed]];
    self.speedLabel.hidden = (stats.analysisDomain.speed == nil);
    
    WSHeartRate heartRate = stats.averageHeartRate;
    self.heartRateLabel.text = [NSString stringWithFormat:@"Avg. Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.accessibilityLabel = [NSString stringWithFormat:@"Average Heart Rate: %@ BPM", [WSFormatterUtils beatsPerMinute:heartRate]];
    self.heartRateLabel.hidden = (stats.analysisDomain.heartRate == nil);
}

- (void)_setGenericLabelProperties:(UILabel *)label {
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    label.adjustsFontForContentSizeCategory = YES;
    label.lineBreakMode = NSLineBreakByWordWrapping;
}
- (void)_addContextMenuInteraction:(UILabel *)label {
    UIContextMenuInteraction *contextMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [label addInteraction:contextMenuInteraction];
    label.userInteractionEnabled = YES;
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
    [self _addContextMenuInteraction:distanceLabel];
    
    [self insertArrangedSubview:distanceLabel atIndex:WSSegmentStatsLabelIndexDistance];
}
- (void)setClimbedLabel:(UILabel *)climbedLabel {
    [self.climbedLabel removeFromSuperview];
    
    _climbedLabel = climbedLabel;
    climbedLabel.textColor = UIColor.altitudeColor;
    [self _setGenericLabelProperties:climbedLabel];
    [self _addContextMenuInteraction:climbedLabel];
    
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
    [self _addContextMenuInteraction:speedLabel];
    
    [self insertArrangedSubview:speedLabel atIndex:WSSegmentStatsLabelIndexSpeed];
}
- (void)setHeartRateLabel:(UILabel *)heartRateLabel {
    [self.heartRateLabel removeFromSuperview];
    
    _heartRateLabel = heartRateLabel;
    heartRateLabel.textColor = UIColor.heartRateColor;
    [self _setGenericLabelProperties:heartRateLabel];
    
    [self insertArrangedSubview:heartRateLabel atIndex:WSSegmentStatsLabelIndexHeartRate];
}

// MARK: - UIContextMenuInteractionDelegate

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    UILabel *label = interaction.view;
    
    WSMeasurementType type;
    NSArray<NSUnit *> *units;
    if (label == self.distanceLabel) {
        type = WSMeasurementTypeDistance;
        units = @[
            NSUnitLength.kilometers,
            NSUnitLength.miles,
        ];
    } else if (label == self.climbedLabel) {
        type = WSMeasurementTypeAltitude;
        units = @[
            NSUnitLength.meters,
            NSUnitLength.feet,
            NSUnitLength.yards,
        ];
    } else if (label == self.speedLabel) {
        type = WSMeasurementTypeSpeed;
        units = @[
            NSUnitSpeed.kilometersPerHour,
            NSUnitSpeed.milesPerHour,
        ];
    } else {
        return nil;
    }
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil
                                                    actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        WSUnitPreferences *unitPreferences = WSUnitPreferences.shared;
        NSUnit *selectedUnit = [unitPreferences unitForType:type];
        
        NSMutableArray<UIMenuElement *> *children = [NSMutableArray arrayWithCapacity:units.count];
        for (NSUnit *unit in units) {
            NSString *title = [WSFormatterUtils abbreviatedUnit:unit];
            UIAction *action = [UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction *menuAction) {
                [unitPreferences setUnit:unit forType:type];
            }];
            action.state = [unit isEqual:selectedUnit] ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            [children addObject:action];
        }
        
        return [UIMenu menuWithTitle:@"Unit" children:children];
    }];
}

@end
