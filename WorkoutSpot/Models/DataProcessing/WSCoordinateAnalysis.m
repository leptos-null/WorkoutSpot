//
//  WSCoordinateAnalysis.m
//  WorkoutSpot
//
//  Created by Leptos on 6/20/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSCoordinateAnalysis.h"

@implementation WSCoordinateAnalysis {
    const CLLocationCoordinate2D *_coordinates;
    vDSP_Length _length;
}

- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coordinates keys:(const double *)keys domain:(double)domain length:(const vDSP_Length)length {
    if (length <= 0) {
        return nil;
    }
    if (self = [super init]) {
        vDSP_Length intropLen = ceil(domain);
        CLLocationCoordinate2D *intropData = malloc(intropLen * sizeof(CLLocationCoordinate2D));
        vDSP_vgenpD(((const double *)coordinates) + 0, 2, keys, 1, ((double *)intropData) + 0, 2, intropLen, length);
        vDSP_vgenpD(((const double *)coordinates) + 1, 2, keys, 1, ((double *)intropData) + 1, 2, intropLen, length);
        
        _coordinates = intropData;
        _length = intropLen;
    }
    return self;
}

- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index {
    NSParameterAssert(index < _length);
    return _coordinates[index];
}
- (WSCoordinateAnalysis *)convertToDomain:(WSDataAnalysis *)dataDomain {
    const double *domain = dataDomain.data;
    const vDSP_Length length = dataDomain.length;
    NSParameterAssert(_length == length);
    
    return [[WSCoordinateAnalysis alloc] initWithCoordinates:_coordinates keys:domain domain:domain[length - 1] length:length];
}

- (MKPolyline *)polylineForRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    return [MKPolyline polylineWithCoordinates:_coordinates + range.location count:range.length];
}

- (WSPointCloud *)globeMapForAltitudes:(WSDataAnalysis *)altitudes {
    NSUInteger const length = _length;
    NSParameterAssert(length == altitudes.length);
    NSAssert(length <= INT_MAX, @"vForce requires length to be represented by an int");
    
    int const len = (length & INT_MAX);
    
    float *floatCoords = malloc(length * 2 * sizeof(float)); // lat-lng interleaved
    vDSP_vdpsp((const double *)_coordinates, 1, floatCoords, 1, length * 2);
    
    float *radii = malloc(length * sizeof(float));
    vDSP_vdpsp(altitudes.data, 1, radii, 1, length);
    float radius = 6378137; // https://en.wikipedia.org/wiki/Earth_radius#Geocentric_radius
    vDSP_vsadd(radii, 1, &radius, radii, 1, length);
    
    // https://en.wikipedia.org/wiki/Spherical_coordinate_system#Cartesian_coordinates
    float *latRad = malloc(len * sizeof(float)); // theta
    float *lngRad = malloc(len * sizeof(float)); // phi
    
    // convert from degrees to radians,
    //   and seperate latitudes and longitudes
    float degToRad = M_PI / 180.0;
    vDSP_vsmul(floatCoords + 0, 2, &degToRad, latRad, 1, len);
    vDSP_vsmul(floatCoords + 1, 2, &degToRad, lngRad, 1, len);
    
    // Earth coordinates use 0 latitude to refer to the equator,
    //   to convert to cartesian coordinates, 0 should refer to the poles
    float *absLat = malloc(len * sizeof(float));
    vvfabsf(absLat, latRad, &len);                    // absLat[n] = | latRad[n] |
    float halfPi = M_PI_2;
    vDSP_vsub(absLat, 1, &halfPi, 0, absLat, 1, len); // absLat[n] = M_PI_2 - absLat[n]
    vvcopysignf(latRad, absLat, latRad, &len);        // latRad[n] = copysign(absLat[n], latRad[n])
    free(absLat);
    
    float *latSin = malloc(len * sizeof(float));
    float *latCos = malloc(len * sizeof(float));
    vvsincosf(latSin, latCos, latRad, &len);
    
    float *lngSin = malloc(len * sizeof(float));
    float *lngCos = malloc(len * sizeof(float));
    vvsincosf(lngSin, lngCos, lngRad, &len);
    
    
    vDSP_Length const xOffset = offsetof(SCNVector3, x)/sizeof(float);
    vDSP_Length const yOffset = offsetof(SCNVector3, y)/sizeof(float);
    vDSP_Length const zOffset = offsetof(SCNVector3, z)/sizeof(float);
    vDSP_Length const dimensions = 3;
    
    SCNVector3 *cartesian = malloc(len * sizeof(SCNVector3));
    vDSP_vmul(latSin, 1, lngCos, 1, ((float *)cartesian) + xOffset, dimensions, len); // x
    vDSP_vmul(latSin, 1, lngSin, 1, ((float *)cartesian) + yOffset, dimensions, len); // y
    
    vDSP_vmul(((float *)cartesian) + xOffset, dimensions, radii, 1, ((float *)cartesian) + xOffset, dimensions, len);
    vDSP_vmul(((float *)cartesian) + yOffset, dimensions, radii, 1, ((float *)cartesian) + yOffset, dimensions, len);
    vDSP_vmul(latCos, 1, radii, 1, ((float *)cartesian) + zOffset, dimensions, len); // z
    
    free(lngCos);
    free(latCos);
    
    free(lngSin);
    free(latSin);
    
    free(lngRad);
    free(latRad);
    
    free(radii);
    free(floatCoords);
    
    WSPointCloud *ret = [[WSPointCloud alloc] initWithPoints:cartesian length:length];
    free(cartesian);
    return ret;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; length = %lu>", [self class], self, _length];
}

- (void)dealloc {
    free((void *)_coordinates);
}

@end

@implementation WSCoordinateAnalysis (WSAnalysisInternals)
- (const CLLocationCoordinate2D *)coordinates {
    return _coordinates;
}
- (vDSP_Length)length {
    return _length;
}
@end
