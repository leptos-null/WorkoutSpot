//
//  WSWorkoutViewCell.h
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface WSWorkoutViewCell : UITableViewCell

@property (class, strong, nonatomic, readonly) NSString *reusableIdentifier;

@property (strong, nonatomic) HKWorkout *workout;

/// A label providing the date of @c workout
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
/// A label providing the time of @c workout
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
/// A label providing the duration of @c workout
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
/// A label providing the distance of @c workout
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;

@end
