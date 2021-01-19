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

/// @discussion
/// The @c coordinates and @c keys arrays should be related
///   such that @c coordinates[n] corresponds to @c keys[n]
///   in the domain of @c keys
/// @param coordinates An array of coordinates of @c length
/// @param keys An array of keys of @c length
/// @param domain A value that descibes the magnitude
///   of the @c keys domain, such that the domain is @c [0, @c domain]
/// @param length The length of each of the input arrays
/// @note @c keys must increase monotonically
- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coordinates keys:(const double *)keys
                             domain:(double)domain length:(const vDSP_Length)length;
/// The coordinate at @c index
- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;
/// Computes the @c CLLocationDistance between @c coordinates on Earth
/// @code
/// spacing[n] = distance(coordinates[n], coordinates[n - 1])
/// @endcode
- (WSDataAnalysis *)stepSpace;
/// The data of the receiver converted into the domain of @c dataDomain data.
/// @discussion
/// The domain of the receiver and @c dataDomain must be the same.
- (WSCoordinateAnalysis *)convertToDomain:(WSDataAnalysis *)dataDomain;
/// A polyline with the coordinates in @c range
- (MKPolyline *)polylineForRange:(NSRange)range;
/// Creates a point cloud using the coordinates of the receiver.
/// @c altitudes are added to the radius at each point.
- (WSPointCloud *)globeMapForAltitudes:(WSDataAnalysis *)altitudes;

@end


@interface WSCoordinateAnalysis (WSAnalysisInternals)

@property (nonatomic, readonly) const CLLocationCoordinate2D *coordinates NS_RETURNS_INNER_POINTER;
@property (nonatomic, readonly) vDSP_Length length;

@end
