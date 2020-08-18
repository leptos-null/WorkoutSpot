//
//  WSGraphView.m
//  WorkoutSpot
//
//  Created by Leptos on 6/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSGraphView.h"
#import "../Models/UIColor+WSColors.h"
#import "../Models/WSAnalysisDomain.h"

@implementation WSGraphView

- (void)drawRect:(CGRect)rect {
    [UIColor.heartRateColor setStroke];
    [self.heartGraph.path stroke];
    
    [UIColor.speedColor setStroke];
    [self.speedGraph.path stroke];
    
    [UIColor.altitudeColor setStroke];
    [self.altitudeGraph.path stroke];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    [self _updateGraphs];
}

- (void)setSegmentStats:(WSSegmentStatistics *)segmentStats {
    _segmentStats = segmentStats;
    
    [self _updateGraphs];
}
- (void)setGraphInsets:(UIEdgeInsets)graphInsets {
    _graphInsets = graphInsets;
    
    [self _updateGraphs];
}

- (void)_updateGraphs {
    WSSegmentStatistics *segmentStats = self.segmentStats;
    WSAnalysisDomain *analysisDomain = segmentStats.analysisDomain;
    NSRange range = segmentStats.range;
    CGSize size = self.bounds.size;
    UIEdgeInsets insets = self.graphInsets;
    
    _heartGraph = [analysisDomain.heartRate graphGuideForSize:size insets:insets range:range];
    _speedGraph = [analysisDomain.speed graphGuideForSize:size insets:insets range:range];
    _altitudeGraph = [analysisDomain.altitude graphGuideForSize:size insets:insets range:range];
    
    [self setNeedsDisplay];
}

- (NSString *)description {
    NSString *preDesc = [super description];
    NSString *desc = [NSString stringWithFormat:@"; segmentStats = %@; graphInsets = %@; "
                      "heartGraph = %@; speedGraph = %@; altitudeGraph = %@>",
                      self.segmentStats, NSStringFromUIEdgeInsets(self.graphInsets),
                      self.heartGraph, self.speedGraph, self.altitudeGraph];
    
    return [preDesc stringByReplacingCharactersInRange:NSMakeRange(preDesc.length - 1, 1) withString:desc];
}

@end
