//
//  WSViewController.h
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
#import <MapKit/MapKit.h>

#import "../Models/WSWorkoutAnalysis.h"
#import "../Views/WSGraphView.h"
#import "../Views/StatsViews/WSPointStatsView.h"
#import "../Views/StatsViews/WSSegmentStatsView.h"
#import "../Views/StatsViews/WSExtremaStatsView.h"

@interface WSViewController : UIViewController <MKMapViewDelegate, UIScrollViewDelegate, UIContextMenuInteractionDelegate>

+ (instancetype)fromStoryboard;

/// The workout analysis the receiver represents
@property (strong, nonatomic) WSWorkoutAnalysis *workoutAnalysis;
/// The domain being represented by the receiver
@property (strong, nonatomic, readonly) WSAnalysisDomain *activeDomain;
/// The map overlay that represents the entire route
@property (strong, nonatomic, readonly) MKPolyline *routeOverlay;
/// The map overlay that represents the @c viewRange of the route
/// @discussion On iOS 14 and later, this matches the entire route
/// overlay, and the renderer is used to only render a portion of the route.
@property (strong, nonatomic, readonly) MKPolyline *segmentOverlay;
/// The range of @c activeDomain to view
@property (nonatomic) NSRange viewRange;
/// The index in @c activeDomain to view
@property (nonatomic) NSUInteger pointIndex;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet WSPointStatsView *pointStatsView;
@property (strong, nonatomic) IBOutlet WSSegmentStatsView *segmentStatsView;

/// @c YES shows point related elements.
/// @c NO hides point related elements.
@property (nonatomic, getter=isShowingPointStats) BOOL showPointStats;
@property (strong, nonatomic) IBOutlet UIView *pointStatsEffectsView;

@property (strong, nonatomic) IBOutlet UIView *pointSlideLineView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pointSlideLineCenter;

@property (strong, nonatomic) IBOutlet WSGraphView *graphView;
@property (strong, nonatomic) IBOutlet UIScrollView *graphScrollViewProxy;
@property (strong, nonatomic) IBOutlet UIView *fakeScrollContent;

@property (strong, nonatomic) IBOutlet WSExtremaStatsView *maximaStatsView;
@property (strong, nonatomic) IBOutlet WSExtremaStatsView *minimaStatsView;
/// The label that indicates the minimum value of the domain
@property (strong, nonatomic) IBOutlet UILabel *leftDomainLabel;
/// The label that indicates the maximum value of the domain
@property (strong, nonatomic) IBOutlet UILabel *rightDomainLabel;
/// Each segment has an index reflecting a @c WSDomainKey
@property (strong, nonatomic) IBOutlet UISegmentedControl *domainControl;

@property (strong, nonatomic) IBOutlet WSGraphView *graphPreview;
@property (strong, nonatomic) IBOutlet UIView *previewSegmentView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewSegmentLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewSegmentTrailing;

/// Zoom @c mapView in on @c routeOverlay
/// @discussion Whether the zoom is animated
/// is determined by the view controller state
- (void)focusMapOnRoute;

@end
