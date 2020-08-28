//
//  WSEmptyListView.h
//  WorkoutSpot
//
//  Created by Leptos on 8/13/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

/// A view that is shown in the place of an empty list
@interface WSEmptyListView : UIView
/// Create a view from its backing interface file
+ (instancetype)fromNibWithOwner:(id)owner;
/// The label intended to briefly convey why the list is empty
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
/// The label intended to convey the details of why the list is empty
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;

@end
