//
//  WSViewController.m
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSViewController.h"
#import "../Services/WSFormatterUtils.h"
#import "../Models/UIColor+WSColors.h"
#import "../Models/UIBezierPath+WSCenteredCircle.h"
#import "../Models/WSPointStatistics.h"
#import "../Models/WSSegmentStatistics.h"
#import "../Models/NSMutableAttributedString+WSAppending.h"

typedef NS_ENUM(NSUInteger, WSMapOverlayIndex) {
    /* lower index -> below higher layers (index 1 covers index 0) */
    WSMapOverlayIndexRoute,
    WSMapOverlayIndexSegment,
    /* higher index -> above lower layers (index 1 covers index 0) */
};

@implementation WSViewController {
    MKPointAnnotation *_pointAnnotation;
    MKPolylineRenderer *_routeRenderer;
    MKPolylineRenderer *_segmentRenderer;
    
    CAShapeLayer *_heartPointLayer;
    CAShapeLayer *_speedPointLayer;
    CAShapeLayer *_altitudePointLayer;
}

+ (instancetype)fromStoryboard {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Workout" bundle:[NSBundle bundleForClass:self]];
    return [storyboard instantiateInitialViewController];
}

// MARK: - Properties

- (void)setRouteOverlay:(MKPolyline *)routeOverlay {
    MKPolyline *existing = self.routeOverlay;
    _routeOverlay = routeOverlay;
    
    MKMapView *mapView = self.mapView;
    if (existing) {
        [mapView removeOverlay:existing];
    }
    if (routeOverlay == nil) {
        return;
    }
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:self.routeOverlay];
    renderer.strokeColor = UIColor.routeColor;
    renderer.lineWidth = 6;
    _routeRenderer = renderer;
    
    [mapView insertOverlay:routeOverlay atIndex:WSMapOverlayIndexRoute];
    UIEdgeInsets padding = UIEdgeInsetsMake(18, 18, 18, 18);
    BOOL shouldAnimate = (self.navigationController != nil);
    [mapView setVisibleMapRect:routeOverlay.boundingMapRect edgePadding:padding animated:shouldAnimate];
}

- (void)setSegmentOverlay:(MKPolyline *)segmentOverlay {
    MKPolyline *existing = self.segmentOverlay;
    _segmentOverlay = segmentOverlay;
    
    MKMapView *mapView = self.mapView;
    if (existing) {
        [mapView removeOverlay:existing];
    }
    if (segmentOverlay == nil) {
        return;
    }
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:self.segmentOverlay];
    renderer.strokeColor = UIColor.segmentColor;
    renderer.lineWidth = 6;
    _segmentRenderer = renderer;
    
    [mapView insertOverlay:segmentOverlay atIndex:WSMapOverlayIndexSegment];
}

- (void)setWorkoutAnalysis:(WSWorkoutAnalysis *)workoutAnalysis {
    _workoutAnalysis = workoutAnalysis;
    
    __weak __typeof(self) weakself = self;
    [workoutAnalysis setHandler:^(WSWorkoutAnalysis *analysis, NSError *error) {
        if (error) {
            NSLog(@"WSWorkoutAnalysisCompleted: %@", error);
            return;
        }
        [weakself domainSegmentDidChange:weakself.domainControl];
    }];
    
    double meters = [workoutAnalysis.workout.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
    self.title = [WSFormatterUtils abbreviatedMeters:meters];
}

- (void)setActiveDomain:(WSAnalysisDomain *)activeDomain {
    [self setActiveDomain:activeDomain sameWorkout:NO];
}
/// Set @c sameWorkout to @c YES if @c activeDomain and the domain it's replacing represent the same data
- (void)setActiveDomain:(WSAnalysisDomain *)activeDomain sameWorkout:(BOOL)sameWorkout {
    WSAnalysisDomain *previousDomain = self.activeDomain;
    
    _activeDomain = activeDomain;
    
    NSRange const domainRange = activeDomain.fullRange;
    WSSegmentStatistics *fullStats = [[WSSegmentStatistics alloc] initWithWorkoutAnalysis:self.workoutAnalysis
                                                                                   domain:activeDomain range:domainRange];
    
    self.graphView.segmentStats = fullStats;
    self.graphPreview.segmentStats = fullStats;
    
    if (@available(iOS 14.0, *)) {
        self.segmentOverlay = fullStats.route;
    }
    if (sameWorkout && (previousDomain != nil)) {
        NSUInteger pointIndex = [activeDomain indexFromIndex:self.pointIndex inDomain:previousDomain];
        NSRange viewRange = [activeDomain rangeFromRange:self.viewRange inDomain:previousDomain];
        
        self.pointIndex = pointIndex;
        self.viewRange = viewRange;
        [self _setScrollProxyPropertiesForGraphRange:viewRange];
    } else {
        self.pointIndex = 0;
        self.viewRange = domainRange;
        self.routeOverlay = fullStats.route;
    }
    
    // this denominator is not particullarly meaningful
    self.graphScrollViewProxy.maximumZoomScale = MAX(1, activeDomain.fullRange.length / 24.0);
}

- (void)setViewRange:(NSRange)viewRange {
    WSWorkoutAnalysis *workoutAnalysis = self.workoutAnalysis;
    WSAnalysisDomain *analysis = self.activeDomain;
    if (analysis == nil) {
        return;
    }
    
    NSRange const fullRange = analysis.fullRange;
    viewRange = NSIntersectionRange(viewRange, fullRange);
    _viewRange = viewRange;
    
    WSSegmentStatistics *segmentStats = [[WSSegmentStatistics alloc] initWithWorkoutAnalysis:workoutAnalysis domain:analysis range:viewRange];
    self.graphView.segmentStats = segmentStats;
    
    [self setPointIndex:self.pointIndex];
    
    self.segmentStatsView.stats = segmentStats;
    
    NSUInteger maxRangeIdx = NSRangeMaxIndex(fullRange);
    NSUInteger maxViewIdx = NSRangeMaxIndex(viewRange);
    CGFloat startPercent = (CGFloat)viewRange.location/maxRangeIdx;
    CGFloat endPercent = (CGFloat)maxViewIdx/maxRangeIdx;
    
    CGFloat containerWidth = CGRectGetWidth(self.graphPreview.bounds);
    self.previewSegmentLeading.constant = startPercent * containerWidth;
    self.previewSegmentTrailing.constant = containerWidth * (1.0 - endPercent);
    
    if (@available(iOS 14.0, *)) {
        WSAnalysisDomain *distDomain = workoutAnalysis.distanceDomain;
        
        NSRange distRange = [distDomain rangeFromRange:viewRange inDomain:analysis];
        NSUInteger maxDistanceIdx = NSRangeMaxIndex(distDomain.fullRange);
        NSUInteger endIdx = NSRangeMaxIndex(distRange);
        
        startPercent = (CGFloat)distRange.location/maxDistanceIdx;
        endPercent = (CGFloat)endIdx/maxDistanceIdx;
        
        _segmentRenderer.strokeStart = startPercent;
        _segmentRenderer.strokeEnd = endPercent;
    } else {
        self.segmentOverlay = segmentStats.route;
    }
}

- (void)setPointIndex:(NSUInteger)pointIndex {
    _pointIndex = pointIndex;
    
    WSAnalysisDomain *analysis = self.activeDomain;
    WSPointStatistics *pointStats = analysis[pointIndex];
    
    _pointAnnotation.coordinate = pointStats.coordinate;
    
    CGFloat const circleRadii = 4;
    WSGraphView *graphView = self.graphView;
    
    _heartPointLayer.path = [[graphView.heartGraph circleForIndex:pointIndex radius:circleRadii] CGPath];
    _speedPointLayer.path = [[graphView.speedGraph circleForIndex:pointIndex radius:circleRadii] CGPath];
    _altitudePointLayer.path = [[graphView.altitudeGraph circleForIndex:pointIndex radius:circleRadii] CGPath];
    
    self.pointStatsView.stats = pointStats;
}

// MARK: - UI Setters

- (void)setMapView:(MKMapView *)mapView {
    _mapView = mapView;
    
    _pointAnnotation = [MKPointAnnotation new];
    [mapView addAnnotation:_pointAnnotation];
}

- (void)setGraphScrollViewProxy:(UIScrollView *)graphScrollViewProxy {
    _graphScrollViewProxy = graphScrollViewProxy;
    
    graphScrollViewProxy.isAccessibilityElement = YES;
    graphScrollViewProxy.accessibilityLabel = @"Graph";
    graphScrollViewProxy.accessibilityHint = @"Adjust selection";
    graphScrollViewProxy.accessibilityTraits = UIAccessibilityTraitAdjustable | UIAccessibilityTraitAllowsDirectInteraction;
    graphScrollViewProxy.panGestureRecognizer.minimumNumberOfTouches = 2;
}

- (void)setGraphView:(WSGraphView *)graphView {
    _graphView = graphView;
    
    graphView.graphInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    
    CALayer *graphLayer = graphView.layer;
    
    _heartPointLayer = [CAShapeLayer layer];
    [graphLayer addSublayer:_heartPointLayer];
    
    _speedPointLayer = [CAShapeLayer layer];
    [graphLayer addSublayer:_speedPointLayer];
    
    _altitudePointLayer = [CAShapeLayer layer];
    [graphLayer addSublayer:_altitudePointLayer];
    
    [self _setLayerColors];
}

- (void)setGraphPreview:(WSGraphView *)graphPreview {
    _graphPreview = graphPreview;
    
    graphPreview.graphInsets = UIEdgeInsetsMake(1, 1, 1, 1);
    graphPreview.backgroundColor = [UIColor.routeColor colorWithAlphaComponent:0.4];
}

- (void)setPreviewSegmentView:(UIView *)previewSegmentView {
    _previewSegmentView = previewSegmentView;
    
    previewSegmentView.backgroundColor = UIColor.segmentColor;
}

- (void)setDomainControl:(UISegmentedControl *)domainControl {
    _domainControl = domainControl;
    
    [self domainSegmentDidChange:domainControl];
}

// MARK: - View Controller overrides

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    __weak __typeof(self) weakself = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // this helps animations with the graph appear smooth
        [weakself setViewRange:weakself.viewRange];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // in addition to the `alongsideTransition` block (above)
        //   this code helps to make sure states are still in sync
        NSRange const range = weakself.viewRange;
        [weakself _setScrollProxyPropertiesForGraphRange:range];
        // just to make sure everything went ok
        [weakself _setGraphRangeForScrollProxy:weakself.graphScrollViewProxy];
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self _setLayerColors];
    }
}

// MARK: - Private methods

- (IBAction)graphPanGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.numberOfTouches == 1) {
        UIScrollView *scrollView = self.graphScrollViewProxy;
        CGPoint touch = [gesture locationOfTouch:0 inView:scrollView];
        
        CGFloat percent = touch.x / scrollView.contentSize.width;
        self.pointIndex = [self.activeDomain indexForPercent:percent];
    }
}

- (IBAction)domainSegmentDidChange:(UISegmentedControl *)segmentControl {
    WSWorkoutAnalysis *workoutAnalysis = self.workoutAnalysis;
    WSAnalysisDomain *domain = nil;
    switch (segmentControl.selectedSegmentIndex) {
        case 0: {
            domain = workoutAnalysis.timeDomain;
        } break;
        case 1: {
            domain = workoutAnalysis.distanceDomain;
        } break;
        default:
            break;
    }
    [self setActiveDomain:domain sameWorkout:YES];
}

- (UIBezierPath *)_circleAtPoint:(CGPoint)point radius:(CGFloat)radius {
    CGRect rect;
    rect.origin.x = point.x - radius;
    rect.origin.y = point.y - radius;
    rect.size.width = radius * 2;
    rect.size.height = radius * 2;
    return [UIBezierPath bezierPathWithOvalInRect:rect];
}

- (void)_setGraphRangeForScrollProxy:(UIScrollView *)scrollView {
    CGFloat percentStart = scrollView.contentOffset.x / scrollView.contentSize.width;
    if (isnan(percentStart)) {
        return;
    }
    NSRange range = self.activeDomain.fullRange;
    
    range.location = [self.activeDomain indexForPercent:percentStart];
    range.length /= scrollView.zoomScale;
    
    self.viewRange = range;
}

- (void)_setScrollProxyPropertiesForGraphRange:(NSRange)range {
    UIScrollView *scrollView = self.graphScrollViewProxy;
    NSRange const fullRange = self.activeDomain.fullRange;
    
    scrollView.zoomScale = (CGFloat)fullRange.length / range.length;
    scrollView.contentOffset = CGPointMake(scrollView.contentSize.width * range.location / fullRange.length, 0);
}

- (void)_setLayerColors {
    _heartPointLayer.fillColor = [UIColor.heartRateColor CGColor];
    _speedPointLayer.fillColor = [UIColor.speedColor CGColor];
    _altitudePointLayer.fillColor = [UIColor.altitudeColor CGColor];
}

// MARK: - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if (overlay == self.routeOverlay) {
        return _routeRenderer;
    }
    if (overlay == self.segmentOverlay) {
        return _segmentRenderer;
    }
    MKOverlayRenderer *defaultRenderer = [[MKOverlayRenderer alloc] initWithOverlay:overlay];
    return defaultRenderer;
}

// MARK: - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.fakeScrollContent;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self _setGraphRangeForScrollProxy:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _setGraphRangeForScrollProxy:scrollView];
}

// MARK: - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; view = %@; mapView = %@; pointStatsView = %@; segmentStatsView = %@; graphView = %@; "
            "workoutAnalysis = %@; routeOverlay = %@; segmentOverlay = %@; "
            "viewRange = %@; pointIndex = %lu; "
            "graphScrollViewProxy = %@; fakeScrollContent = %@; graphPreview = %@>",
            [self class], self, self.viewIfLoaded, self.mapView, self.pointStatsView, self.segmentStatsView, self.graphView,
            self.workoutAnalysis, self.routeOverlay, self.segmentOverlay,
            NSStringFromRange(self.viewRange), self.pointIndex,
            self.graphScrollViewProxy, self.fakeScrollContent, self.graphPreview];
}

@end


@implementation WSGraphGuide (WSPointDrawing)

- (UIBezierPath *)circleForIndex:(NSUInteger)index radius:(CGFloat)radius {
    if (NSLocationInRange(index, self.range)) {
        CGPoint center = [self pointForIndex:index];
        return [UIBezierPath bezierPathWithCircleCenter:center radius:radius];
    }
    return NULL;
}

@end