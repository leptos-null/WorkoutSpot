//
//  WSTableViewController.h
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface WSTableViewController : UITableViewController

@property (strong, nonatomic) HKHealthStore *healthStore;

@end
