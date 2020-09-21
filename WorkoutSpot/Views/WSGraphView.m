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
    [self.heartRateGraph.path stroke];
    
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
    WSGraphConfiguration *graphConfig = [WSGraphConfiguration new];
    graphConfig.size = self.bounds.size;
    graphConfig.edgeInsets = self.graphInsets;
    
    _heartRateGraph = [segmentStats heartRateGraphGuideWithConfiguration:graphConfig];
    _speedGraph = [segmentStats speedGraphGuideWithConfiguration:graphConfig];
    _altitudeGraph = [segmentStats altitudeGraphGuideWithConfiguration:graphConfig];
    
    [self setNeedsDisplay];
}

- (NSString *)description {
    NSString *preDesc = [super description];
    NSString *desc = [NSString stringWithFormat:@"; segmentStats = %@; graphInsets = %@; "
                      "heartRateGraph = %@; speedGraph = %@; altitudeGraph = %@>",
                      self.segmentStats, NSStringFromUIEdgeInsets(self.graphInsets),
                      self.heartRateGraph, self.speedGraph, self.altitudeGraph];
    
    return [preDesc stringByReplacingCharactersInRange:NSMakeRange(preDesc.length - 1, 1) withString:desc];
}

@end
