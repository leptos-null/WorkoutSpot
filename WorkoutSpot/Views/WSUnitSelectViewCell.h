//
//  WSUnitSelectViewCell.h
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../Services/WSUnitPreferences.h"

@interface WSUnitSelectViewCell : UITableViewCell

@property (class, strong, nonatomic, readonly) NSString *reusableIdentifier;

@property (nonatomic) WSMeasurementType type;

@property (strong, nonatomic) IBOutlet UILabel *dimensionLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *unitSegment;

@end
