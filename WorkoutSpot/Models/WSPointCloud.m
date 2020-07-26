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

- (float)rollingDistanceOverRange:(NSRange)range {
    if (range.length == 0) {
        return NAN;
    }
    // TODO: benchmark against each computation in Accelerate
    // e.g.
    // vDSP_vsubD(data, 1, data + 1, 1, xDiff, 1, length);
    // vDSP_vsubD(data, 1, data + 1, 1, yDiff, 1, length);
    // vDSP_vsubD(data, 1, data + 1, 1, zDiff, 1, length);
    // vDSP_vsq(xDiff, 1, xSqr, 1, length);
    // vDSP_vsq(yDiff, 1, ySqr, 1, length);
    // vDSP_vsq(zDiff, 1, zSqr, 1, length);
    // vDSP_vadd(xSqr, 1, ySqr, 1, sumSqr, 1, length);
    // vDSP_vadd(sumSqr, 1, zSqr, 1, sumSqr, 1, length);
    // vvsqrtf(sqrRt, sumSqr, &len);
    // vDSP_sve(sqrRt, 1, &dist, length);
    
    float dist = 0;
    const SCNVector3 *vectors = _vectors + range.location;
    for (NSUInteger i = 0; i < (range.length - 1); i++) {
        // sqrt( (a.x - b.x)**2 + (a.y - b.y)**2 + (a.z - b.z)**2 )
        dist += simd_distance(SCNVector3ToFloat3(vectors[i + 1]),
                              SCNVector3ToFloat3(vectors[i + 0]));
    }
    return dist;
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
