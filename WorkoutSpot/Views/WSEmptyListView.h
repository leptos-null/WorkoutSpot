//
//  WSEmptyListView.h
//  WorkoutSpot
//
//  Created by Leptos on 8/13/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSEmptyListView : UIView

+ (instancetype)fromNibWithOwner:(id)owner;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;

@end
