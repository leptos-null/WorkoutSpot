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

@interface WSViewController : UIViewController <MKMapViewDelegate, UIScrollViewDelegate>

+ (instancetype)fromStoryboard;


@property (strong, nonatomic) WSWorkoutAnalysis *workoutAnalysis;
@property (strong, nonatomic, readonly) WSAnalysisDomain *activeDomain;

@property (strong, nonatomic, readonly) MKPolyline *routeOverlay;
// on iOS 14 and later, the segment is a copy of the route
@property (strong, nonatomic, readonly) MKPolyline *segmentOverlay;
/// The range of @c activeDomain to view
@property (nonatomic) NSRange viewRange;
/// The index in @c activeDomain to view
@property (nonatomic) NSUInteger pointIndex;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet WSPointStatsView *pointStatsView;
@property (strong, nonatomic) IBOutlet WSSegmentStatsView *segmentStatsView;

@property (nonatomic, getter=isShowingPointStats) BOOL showPointStats;
@property (strong, nonatomic) IBOutlet UIView *pointStatsEffectsView;

@property (strong, nonatomic) IBOutlet UIView *pointSlideLineView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pointSlideLineCenter;

@property (strong, nonatomic) IBOutlet WSGraphView *graphView;
@property (strong, nonatomic) IBOutlet UIScrollView *graphScrollViewProxy;
@property (strong, nonatomic) IBOutlet UIView *fakeScrollContent;

@property (strong, nonatomic) IBOutlet WSExtremaStatsView *maximaStatsView;
@property (strong, nonatomic) IBOutlet WSExtremaStatsView *minimaStatsView;

@property (strong, nonatomic) IBOutlet UILabel *leftDomainLabel;
@property (strong, nonatomic) IBOutlet UILabel *rightDomainLabel;

@property (strong, nonatomic) IBOutlet UISegmentedControl *domainControl;

@property (strong, nonatomic) IBOutlet WSGraphView *graphPreview;
@property (strong, nonatomic) IBOutlet UIView *previewSegmentView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewSegmentLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewSegmentTrailing;

- (void)focusMapOnRoute;

@end


@interface WSGraphGuide (WSPointDrawing)

/// Create a circle with radius @c radius around the
/// point where @c index is represented on @c path
- (UIBezierPath *)circleForIndex:(NSUInteger)index radius:(CGFloat)radius;

@end
