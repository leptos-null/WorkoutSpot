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

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;

@end
