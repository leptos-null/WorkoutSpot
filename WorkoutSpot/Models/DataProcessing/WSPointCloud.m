//
//  WSPointCloud.m
//  WorkoutSpot
//
//  Created by Leptos on 7/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSPointCloud.h"
#import "NSRange+WSIndex.h"

@implementation WSPointCloud {
    const SCNVector3 *_vectors;
    NSUInteger _length;
}

- (instancetype)initWithPoints:(const SCNVector3 *)vectors length:(const NSUInteger)length {
    if (self = [super init]) {
        size_t byteLength = length * sizeof(SCNVector3);
        SCNVector3 *internal = malloc(byteLength);
        memcpy(internal, vectors, byteLength);
        _vectors = internal;
        _length = length;
    }
    return self;
}

- (SCNVector3)pointAtIndex:(NSUInteger)index {
    NSParameterAssert(index < _length);
    return _vectors[index];
}

- (WSDataAnalysis *)stepSpace {
    // the input to this method is single precision, and the output is double precision
    // somewhere, the format must change, so for performance, do it at the end
    const SCNVector3 *vectors = _vectors;
    const NSUInteger length = _length;
    
    // the below code is intended to work for n-dimensional space
    //   by changing this variable
    vDSP_Length const dimensions = 3;
    
    float *strungSteps = malloc(dimensions * length * sizeof(float));
    
    for (NSUInteger dimension = 0; dimension < dimensions; dimension++) {
        const NSUInteger strungOffset = length * dimension;
        
        // steps[0] = 0
        strungSteps[strungOffset] = 0;
        // steps[n + 1] = vectors[n + 1] - vectors[n]
        vDSP_vsub(((float *)vectors) + dimension, dimensions,
                  ((float *)(vectors + 1)) + dimension, dimensions,
                  strungSteps + strungOffset + 1, 1, length - 1);
        // note that we're reading from interleaved data, but writing serial
        // vectors is
        //   (x1, y1, z1), (x2, y2, z2), ...
        // strungSteps is
        //   [0, Δx12, Δx23, ...], [0, Δy12, Δy23, ...], [0, Δz12, Δz23, ...]
    }
    
    vDSP_vsq(strungSteps, 1, strungSteps, 1, length * dimensions); // steps = steps**2
    
    float *squareSums = calloc(length, sizeof(float));
    
    for (NSUInteger dimension = 0; dimension < dimensions; dimension++) {
        const NSUInteger strungOffset = length * dimension;
        vDSP_vadd(strungSteps + strungOffset, 1, squareSums, 1, squareSums, 1, length); // squareSums += steps[dimension]
    }
    
    NSAssert(length <= INT_MAX, @"vForce requires length to be represented by an int");
    int const len = (length & INT_MAX);
    
    float *squareRoots = malloc(length * sizeof(float));
    vvsqrtf(squareRoots, squareSums, &len); // squareRoots = sqrt(squareSums)
    
    double *distances = malloc(length * sizeof(double));
    vDSP_vspdp(squareRoots, 1, distances, 1, length);
    
    free(squareRoots);
    free(squareSums);
    free(strungSteps);
    
    return [[WSDataAnalysis alloc] initWithInterpolatedData:distances length:length];
}

- (SCNGeometry *)geometryForRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    
    SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithVertices:(_vectors + range.location) count:range.length];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil primitiveType:SCNGeometryPrimitiveTypePoint
                                                               primitiveCount:range.length bytesPerIndex:sizeof(unsigned)];
    element.pointSize = 8;
    element.minimumPointScreenSpaceRadius = 1;
    element.maximumPointScreenSpaceRadius = 20;
    
    SCNGeometry *geo = [SCNGeometry geometryWithSources:@[
        source
    ] elements:@[
        element
    ]];
    return geo;
}

- (id)debugQuickLookObject {
    id geometry = [self geometryForRange:NSMakeRange(0, _length)];
    return [geometry debugQuickLookObject];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; length = %lu>", [self class], self, _length];
}

- (void)dealloc {
    free((void *)_vectors);
}

@end
