//
//  WSWorkoutViewCell.m
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSWorkoutViewCell.h"
#import "../Services/WSUnitPreferences.h"

@implementation WSWorkoutViewCell

+ (NSString *)reusableIdentifier {
    return @"WorkoutCell";
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
        [defaultCenter addObserver:self selector:@selector(_updateLabelsForWorkout) name:NSCurrentLocaleDidChangeNotification object:nil];
    }
    return self;
}

- (void)setWorkout:(HKWorkout *)workout {
    _workout = workout;
    [self _updateLabelsForWorkout];
}

- (void)_updateLabelsForWorkout {
    HKWorkout *workout = self.workout;
    
    NSDate *startDate = workout.startDate;
    NSTimeInterval duration = [workout.endDate timeIntervalSinceDate:startDate];
    double meters = [workout.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
    
    self.dateLabel.text = [WSFormatterUtils dateOnlyFromDate:startDate];
    self.dateLabel.accessibilityLabel = [WSFormatterUtils dateOnlyFromDate:startDate];
    
    self.timeLabel.text = [WSFormatterUtils timeOnlyFromDate:startDate];
    self.timeLabel.accessibilityLabel = [WSFormatterUtils timeOnlyFromDate:startDate];
    
    self.durationLabel.text = [WSFormatterUtils contractedSeconds:duration];
    self.durationLabel.accessibilityLabel = [WSFormatterUtils expandedSeconds:duration];
    
    self.distanceLabel.text = [WSFormatterUtils abbreviatedDistance:meters];
    self.distanceLabel.accessibilityLabel = [WSFormatterUtils expandedDistance:meters];
}

// MARK: - Description

- (NSString *)description {
    NSString *preDesc = [super description];
    NSString *desc = [NSString stringWithFormat:@"; workout = %@; dateLabel = %@; "
                      "timeLabel = %@; durationLabel = %@; distanceLabel = %@>",
                      self.workout, self.dateLabel,
                      self.timeLabel, self.durationLabel, self.distanceLabel];
    NSUInteger replaceLen = 1;
    return [preDesc stringByReplacingCharactersInRange:NSMakeRange(preDesc.length - replaceLen, replaceLen) withString:desc];
}

@end
