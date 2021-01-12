//
//  WSDataAnalysis.m
//  WorkoutSpot
//
//  Created by Leptos on 6/18/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSDataAnalysis.h"

@implementation WSDataAnalysis {
    const double *_data;
    vDSP_Length _length;
}

- (instancetype)initWithData:(const double *)data keys:(const double *)keys domain:(double)domain length:(const vDSP_Length)length {
    if (length <= 0) {
        return nil;
    }
    vDSP_Length intropLen = ceil(domain);
    double *intropData = malloc(intropLen * sizeof(double));
    vDSP_vgenpD(data, 1, keys, 1, intropData, 1, intropLen, length);
    
    return [self initWithInterpolatedData:intropData length:intropLen];
}

- (double)_accelerateFunction:(void (*)(const double *, vDSP_Stride, double *, vDSP_Length))function range:(NSRange)range {
    double ret = 0;
    function(_data + range.location, 1, &ret, range.length);
    return ret;
}

- (double)datumAtIndex:(NSUInteger)index {
    NSParameterAssert(index < _length);
    return _data[index];
}

- (double)averageOverRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    return [self _accelerateFunction:vDSP_meanvD range:range];
}
- (double)maximumOverRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    return [self _accelerateFunction:vDSP_maxvD range:range];
}
- (double)minimumOverRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    return [self _accelerateFunction:vDSP_minvD range:range];
}

- (double)deltaOverRange:(NSRange)range {
    NSParameterAssert(NSRangeMaxIndex(range) < _length);
    if (range.length == 0) {
        return NAN;
    }
    return _data[NSRangeMaxIndex(range)] - _data[range.location];
}

- (WSDataAnalysis *)derivative {
    const vDSP_Length length = _length;
    const double *data = _data;
    
    vDSP_Length derivativeLen = length - 1;
    double *derivativeIndicies = malloc(derivativeLen * sizeof(double));
    double *derivatives = malloc(derivativeLen * sizeof(double));
    
    double const offset = 0.5;
    double const identityScale = 1;
    // derivativeIndicies[n] = offset + n*identityScale
    vDSP_vrampD(&offset, &identityScale, derivativeIndicies, 1, derivativeLen);
    vDSP_vsubD(data, 1, data + 1, 1, derivatives, 1, derivativeLen); // derivatives[n] = data[n + 1] - data[n]
    // assume dx == 1
    
    WSDataAnalysis *ret = [[WSDataAnalysis alloc] initWithData:derivatives keys:derivativeIndicies domain:length length:derivativeLen];
    free(derivativeIndicies);
    free(derivatives);
    
    return ret;
}
- (WSDataAnalysis *)stepSpace {
    const vDSP_Length length = _length;
    const double *data = _data;
    
    double *stepSpaces = malloc(length * sizeof(double));
    stepSpaces[0] = 0;
    vDSP_vsubD(data, 1, data + 1, 1, stepSpaces + 1, 1, length - 1); // stepSpaces[n + 1] = data[n + 1] - data[n]
    
    WSDataAnalysis *ret = [[WSDataAnalysis alloc] initWithInterpolatedData:stepSpaces length:length];
    return ret;
}
- (WSDataAnalysis *)stairCase {
    const vDSP_Length length = _length;
    const double *data = _data;
    
    double *stairs = malloc(length * sizeof(double));
    double const identityScale = 1;
    // stairs[n] = identityScale * sum(A[0:n])
    vDSP_vrsumD(data, 1, &identityScale, stairs, 1, length);
    
    WSDataAnalysis *ret = [[WSDataAnalysis alloc] initWithInterpolatedData:stairs length:length];
    return ret;
}

- (WSDataAnalysis *)clippingToLower:(double)lowerBound upper:(double)upperBound {
    const vDSP_Length length = _length;
    
    double *clipped = malloc(length * sizeof(double));
    vDSP_vclipD(_data, 1, &lowerBound, &upperBound, clipped, 1, length);
    
    WSDataAnalysis *ret = [[WSDataAnalysis alloc] initWithInterpolatedData:clipped length:length];
    return ret;
}

- (WSDataAnalysis *)derivativeInDomain:(WSDataAnalysis *)dataDomain {
    const double *domain = dataDomain->_data;
    const double *range = _data;
    const vDSP_Length rangeLen = _length;
    NSParameterAssert(rangeLen == dataDomain->_length);
    
    vDSP_Length derivativeLen = rangeLen - 1;
    double *derivativeIndicies = malloc(derivativeLen * sizeof(double));
    double *derivatives = malloc(derivativeLen * sizeof(double));
    for (vDSP_Length derivativeIndx = 0; derivativeIndx < derivativeLen; derivativeIndx++) {
        derivativeIndicies[derivativeIndx] = derivativeIndx + 0.5;
        
        double dy = range[derivativeIndx + 1] - range[derivativeIndx];
        double dx = domain[derivativeIndx + 1] - domain[derivativeIndx];
        derivatives[derivativeIndx] = (dx != 0) ? dy/dx : 0;
    }
    
    WSDataAnalysis *ret = [[WSDataAnalysis alloc] initWithData:derivatives keys:derivativeIndicies domain:rangeLen length:derivativeLen];
    free(derivativeIndicies);
    free(derivatives);
    
    return ret;
}

- (WSDataAnalysis *)convertToDomain:(WSDataAnalysis *)dataDomain {
    const double *domain = dataDomain->_data;
    const vDSP_Length length = dataDomain->_length;
    NSParameterAssert(_length == length);
    
    return [[WSDataAnalysis alloc] initWithData:_data keys:domain domain:domain[length - 1] length:length];
}

- (WSGraphGuide *)graphGuideForConfiguration:(WSGraphConfiguration *)configuration {
    NSParameterAssert(NSRangeMaxIndex(configuration.range) < _length);
    return [[WSGraphGuide alloc] initWithVector:_data configuration:configuration];
}

- (id)debugQuickLookObject {
    WSGraphConfiguration *config = [WSGraphConfiguration new];
    config.size = CGSizeMake(400, 400);
    config.range = NSMakeRange(0, _length);
    
    id graphGuide = [self graphGuideForConfiguration:config];
    return [graphGuide debugQuickLookObject];
}

- (NSString *)description {
    NSRange fullRange = NSMakeRange(0, _length);
    return [NSString stringWithFormat:@"<%@: %p; mean = %f; delta = %f; "
            "min = %f; max = %f; length = %lu>",
            [self class], self, [self averageOverRange:fullRange], [self deltaOverRange:fullRange],
            [self minimumOverRange:fullRange], [self maximumOverRange:fullRange], fullRange.length];
}

- (void)dealloc {
    free((void *)_data);
}

@end

@implementation WSDataAnalysis (WSAnalysisInternals)

- (instancetype)initWithInterpolatedData:(const double *)data length:(vDSP_Length)length {
    if (self = [super init]) {
        _data = data;
        _length = length;
    }
    return self;
}

- (const double *)data {
    return _data;
}
- (vDSP_Length)length {
    return _length;
}

@end
