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

- (WSDataAnalysis *)stepSpace {
    NSUInteger const length = _length;
    const CLLocationCoordinate2D *coordinates = _coordinates;
    NSAssert(length <= INT_MAX, @"vForce requires length to be represented by an int");
    
    int const len = (length & INT_MAX);
    
    double *latRad = malloc(length * sizeof(double)); // latitude in radians
    double *lngRad = malloc(length * sizeof(double)); // longitude in radians
    
    // convert from degrees to radians,
    //   and seperate latitudes and longitudes
    double const degToRad = M_PI / 180.0;
    vDSP_vsmulD(&(coordinates->latitude), 2, &degToRad, latRad, 1, length); // latRad = coordinates.latitude * degToRad
    vDSP_vsmulD(&(coordinates->longitude), 2, &degToRad, lngRad, 1, length); // lngRad = coordinates.longitude * degToRad
    
    // https://en.wikipedia.org/wiki/Earth_radius#Fixed_radius
    double const alpha = 6378137; // meters ("semi-major axis")
    double const beta  = 6356752; // meters ("semi-minor axis")
    
    double const alphaSquared = alpha * alpha;
    double const betaSquared = beta * beta;
    
    double const alphaFourth = alphaSquared * alphaSquared;
    double const betaFourth = betaSquared * betaSquared;
    
    // https://en.wikipedia.org/wiki/Earth_radius#Geocentric_radius
    double *spheroidRadii = malloc(length * sizeof(double));
    double *geoSquaredSum = malloc(length * sizeof(double));
    
    double *latSin = malloc(length * sizeof(double));
    double *latCos = malloc(length * sizeof(double));
    
    vvsincos(latSin, latCos, latRad, &len); // latSin = sin(latRad), latCos = cos(latRad)
    
    double *latSinSq = malloc(length * sizeof(double));
    double *latCosSq = malloc(length * sizeof(double));
    
    vDSP_vsqD(latSin, 1, latSinSq, 1, length); // geoSinBuild = latSin**2
    vDSP_vsqD(latCos, 1, latCosSq, 1, length); // geoCosBuild = latCos**2
    
    // spheroidRadii = alphaFourth*geoCosBuild + betaFourth*geoSinBuild
    vDSP_vsmsmaD(latCosSq, 1, &alphaFourth, latSinSq, 1, &betaFourth, spheroidRadii, 1, length);
    // geoSquaredSum = alphaSquared*geoCosBuild + betaSquared*geoSinBuild
    vDSP_vsmsmaD(latCosSq, 1, &alphaSquared, latSinSq, 1, &betaSquared, geoSquaredSum, 1, length);
    
    vvdiv(spheroidRadii, spheroidRadii, geoSquaredSum, &len); // spheroidRadii /= geoSquaredSum
    vvsqrt(spheroidRadii, spheroidRadii, &len); // spheroidRadii = sqrt(adjustedRadii)
    
    free(latCosSq);
    free(latSinSq);
    
    free(geoSquaredSum);
    
    // https://en.wikipedia.org/wiki/Haversine_formula#Formulation
    NSUInteger const deltasLength = (length - 1);
    int const deltasLen = (len - 1);
    // for consistency, these stepped vectors should have the relation `step[n] = op(vec[n + 1], vec[n])`
    double *deltaLat = malloc(deltasLength * sizeof(double));
    double *deltaLng = malloc(deltasLength * sizeof(double));
    
    double const halfValue = 0.5;
    vDSP_vsbsmD(latRad + 1, 1, latRad, 1, &halfValue, deltaLat, 1, deltasLength); // deltaLat[n] = (latRad[n + 1] - latRad[n]) * halfValue
    vDSP_vsbsmD(lngRad + 1, 1, lngRad, 1, &halfValue, deltaLng, 1, deltasLength); // deltaLng[n] = (lngRad[n + 1] - lngRad[n]) * halfValue
    
    vvsin(deltaLat, deltaLat, &len); // deltaLat = sin(deltaLat)
    vvsin(deltaLng, deltaLng, &len); // deltaLng = sin(deltaLng)
    
    vDSP_vsqD(deltaLat, 1, deltaLat, 1, deltasLength); // deltaLat = deltaLat**2
    vDSP_vsqD(deltaLng, 1, deltaLng, 1, deltasLength); // deltaLng = deltaLng**2
    
    double *innerWorking = malloc(deltasLength * sizeof(double));
    vDSP_vmulD(latCos, 1, latCos + 1, 1, innerWorking, 1, deltasLength); // innerWorking[n] = latCos[n + 1] * latCos[n]
    vDSP_vmaD(innerWorking, 1, deltaLng, 1, deltaLat, 1, innerWorking, 1, deltasLength); // innerWorking = innerWorking * deltaLng + deltaLat
    vvsqrt(innerWorking, innerWorking, &deltasLen); // innerWorking = sqrt(innerWorking)
    vvasin(innerWorking, innerWorking, &deltasLen); // innerWorking = asin(innerWorking)
    
    double *distances = malloc(length * sizeof(double));
    distances[0] = 0;
    // distances[n + 1] = (spheroidRadii[n + 1] + spheroidRadii[n]) * innerWorking
    vDSP_vamD(spheroidRadii + 1, 1, spheroidRadii, 1, innerWorking, 1, distances + 1, 1, deltasLength);
    
    free(innerWorking);
    free(spheroidRadii);
    
    free(deltaLng);
    free(deltaLat);
    
    free(latCos);
    free(latSin);
    
    free(lngRad);
    free(latRad);
    
    return [[WSDataAnalysis alloc] initWithInterpolatedData:distances length:length];
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
    // the input to this method is double precision, and the output is single precision
    // somewhere, the format must change, so for performance, do it at the beginning
    NSUInteger const length = _length;
    NSParameterAssert(length == altitudes.length);
    NSAssert(length <= INT_MAX, @"vForce requires length to be represented by an int");
    
    int const len = (length & INT_MAX);
    
    float *floatCoords = malloc(length * 2 * sizeof(float)); // lat-lng interleaved
    vDSP_vdpsp((const double *)_coordinates, 1, floatCoords, 1, length * 2);
    
    float *height = malloc(length * sizeof(float));
    vDSP_vdpsp(altitudes.data, 1, height, 1, length);
    
    // https://en.wikipedia.org/wiki/Geographic_coordinate_conversion#From_geodetic_to_ECEF_coordinates
    float *latRad = malloc(length * sizeof(float)); // latitude in radians
    float *lngRad = malloc(length * sizeof(float)); // longitude in radians
    
    // convert from degrees to radians,
    //   and seperate latitudes and longitudes
    float degToRad = M_PI / 180.0;
    vDSP_vsmul(floatCoords + 0, 2, &degToRad, latRad, 1, length);
    vDSP_vsmul(floatCoords + 1, 2, &degToRad, lngRad, 1, length);
    
    float *latSin = malloc(length * sizeof(float));
    float *latCos = malloc(length * sizeof(float));
    vvsincosf(latSin, latCos, latRad, &len); // latSin = sin(latRad), latCos = cos(latRad)
    
    float *lngSin = malloc(length * sizeof(float));
    float *lngCos = malloc(length * sizeof(float));
    vvsincosf(lngSin, lngCos, lngRad, &len); // lngSin = sin(lngRad), lngCos = cos(lngRad)
    
    // https://en.wikipedia.org/wiki/Earth_radius#Fixed_radius
    float const alpha = 6378137; // meters ("semi-major axis")
    float const beta  = 6356752; // meters ("semi-minor axis")
    
    float const betaAlphaSqrRatio = (beta * beta)/(alpha * alpha);
    float const firstEccentricitySqr = 1 - betaAlphaSqrRatio;
    
    // http://clynchg3c.com/Technote/geodesy/radiigeo.pdf
    float *primeVertical = malloc(length * sizeof(float)); // "prime vertical radius of curvature"
    
    vDSP_vsq(latSin, 1, primeVertical, 1, length); // primeVertical = latSin**2
    float const negateFirstEccSqr = -firstEccentricitySqr;
    float const floatingUnit = 1;
    // primeVertical = primeVertical * negateFirstEccSqr + floatingUnit
    vDSP_vsmsa(primeVertical, 1, &negateFirstEccSqr, &floatingUnit, primeVertical, 1, length);
    vvsqrtf(primeVertical, primeVertical, &len); // primeVertical = sqrt(primeVertical)
    vDSP_svdiv(&alpha, primeVertical, 1, primeVertical, 1, length); // primeVertical = alpha/primeVertical
    
    float *latCosRadii = malloc(length * sizeof(float));
    vDSP_vam(primeVertical, 1, height, 1, latCos, 1, latCosRadii, 1, length); // latCosRadii = (primeVertical + height) * latCos
    // primeVertical = primeVertical * betaAlphaSqrRatio + height
    vDSP_vsma(primeVertical, 1, &betaAlphaSqrRatio, height, 1, primeVertical, 1, length);
    
    vDSP_Length const dimensions = sizeof(SCNVector3)/sizeof(float);
    SCNVector3 *cartesian = malloc(length * sizeof(SCNVector3));
    vDSP_vmul(latCosRadii,   1, lngCos, 1, &(cartesian->x), dimensions, length); // cartesian.x = latCosRadii * lngCos
    vDSP_vmul(latCosRadii,   1, lngSin, 1, &(cartesian->y), dimensions, length); // cartesian.y = latCosRadii * lngSin
    vDSP_vmul(primeVertical, 1, latSin, 1, &(cartesian->z), dimensions, length); // cartesian.z = primeVertical * latSin
    
    free(latCosRadii);
    free(primeVertical);
    
    free(lngCos);
    free(latCos);
    
    free(lngSin);
    free(latSin);
    
    free(lngRad);
    free(latRad);
    
    free(height);
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
