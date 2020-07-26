//
//  WSCoordinateAnalysis.h
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "WSDataAnalysis.h"
#import "WSPointCloud.h"

/// Coordinate Analysis provides a model to store
///   and work with coordinates.
@interface WSCoordinateAnalysis : NSObject

- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coordinates keys:(const double *)keys
                             domain:(double)domain length:(const vDSP_Length)length;

- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;

- (WSCoordinateAnalysis *)convertToDomain:(WSDataAnalysis *)dataDomain;

- (MKPolyline *)polylineForRange:(NSRange)range;

- (WSPointCloud *)globeMapForAltitudes:(WSDataAnalysis *)altitudes;

@end


@interface WSCoordinateAnalysis (WSAnalysisInternals)

@property (nonatomic, readonly) const CLLocationCoordinate2D *coordinates NS_RETURNS_INNER_POINTER;
@property (nonatomic, readonly) vDSP_Length length;

@end
