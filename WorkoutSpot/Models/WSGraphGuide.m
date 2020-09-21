//
//  WSGraphGuide.m
//  WorkoutSpot
//
//  Created by Leptos on 6/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSGraphGuide.h"
#import "../Models/UIBezierPath+WSCenteredCircle.h"
#import "NSRange+WSIndex.h"

@implementation WSGraphGuide {
    const double *_dataValues;
    vDSP_Length _dataLength;
    // external-index to internal-index ratio
    double _indexFactor;
    
    CGFloat _xScale;
    CGFloat _yScale;
}

/// Generates a double-precision ramped vector of @c outputLength evenly spaced over @c [0, @c inputLength)
/// @discussion The operation is:
/// @code
/// for (n = 0; n < N; ++n)
///     output[n] = n * (inputLength - 1)/outputLength;
/// @endcode
static void ws_vRampD(double *const output, vDSP_Stride const stride, vDSP_Length const inputLength, vDSP_Length const outputLength) {
    double const controlSpacing = (double)(inputLength - 1)/outputLength;
    double const zero = 0;
    vDSP_vrampD(&zero, &controlSpacing, output, stride, outputLength); // output = 0 + i * controlSpacing
}

/// Generates a double-precision smoothstep vector of @c outputLength to smooth data of @c inputLength
/// @discussion The operation is:
/// @code
/// for (n = 0; n < N; ++n) {
///     x = n * (inputLength - 1)/outputLength;
///     xInt = trunc(x); // int component of x
///     a = x - xInt; // fraction component of x
///     smoothstep = 3 * (a**2) - 2 * (a**3);
///     output[n] = xInt + smoothstep;
/// }
/// @endcode
static void ws_vSmoothstepD(double *const output, vDSP_Stride const stride, vDSP_Length const inputLength, vDSP_Length const outputLength) {
    double *xRamp = malloc(outputLength * sizeof(double));
    double *xFract = malloc(outputLength * sizeof(double));
    double *xInt = malloc(outputLength * sizeof(double));
    
    ws_vRampD(xRamp, 1, inputLength, outputLength);    // xRamp = i * (inputLength - 1)/outputLength
    vDSP_vfracD(xRamp, 1, xFract, 1, outputLength);    // xFract = fract(xRamp)
    vDSP_vsubD(xFract, 1, xRamp, 1, xInt, 1, outputLength); // xInt = xRamp - xFract
    
    double *smoothstep = xRamp; // we're done using xRamp, rename and re-use memory
    // poison xRamp
    
    /*
     * the algorithm we want is
     * smoothControl = (3 - 2 * xFract) * xFract * xFract + (xRamp - xFract)
     */
    double const negativeTwo = -2;
    double const three = 3;
    vDSP_vsmsaD(xFract, 1, &negativeTwo, &three, smoothstep, 1, outputLength); // smoothstep = xFract * -2 + 3
    vDSP_vmulD(xFract, 1, smoothstep, 1, smoothstep, 1, outputLength);         // smoothstep = xFract * smoothstep
    vDSP_vmaD(xFract, 1, smoothstep, 1, xInt, 1, output, stride, outputLength); // smoothControl = xFract * smoothstep + xInt
    
    free(smoothstep);
    free(xFract);
    free(xInt);
}

- (instancetype)initWithVector:(const double *)vector configuration:(WSGraphConfiguration *)config {
    NSRange const range = config.range;
    CGSize const size = config.size;
    UIEdgeInsets const insets = config.edgeInsets;
    WSGraphSmoothingTechnique const technique = config.smoothingTechnique;
    
    if (range.length == 0 || size.width <= 0) {
        return nil;
    }
    if (self = [super init]) {
        _size = size;
        _insets = insets;
        _range = range;
        
        CGFloat const intendedGraphicPerDataPoint = M_PI; // graphic points per data point
        
        CGFloat const effectiveWidth = size.width - (insets.left + insets.right);
        CGFloat const effectiveHeight = size.height - (insets.bottom + insets.top);
        
        BOOL applySmoothing;
        switch (technique) {
            case WSGraphSmoothingTechniqueLinear:
            case WSGraphSmoothingTechniqueQuadratic: {
                applySmoothing = YES;
            } break;
            default: {
                applySmoothing = NO;
            } break;
        }
        vDSP_Length interpolationSmoothing = applySmoothing ? 4 : 1;
        double decimationCoefficient = applySmoothing ? 1 : intendedGraphicPerDataPoint;
        
        // this isn't super important, select any rouding technique
        vDSP_Length const intendedFinalPoints = ceil(effectiveWidth/intendedGraphicPerDataPoint);
        double const inputGraphicPerDataPoint = effectiveWidth/(double)range.length;
        vDSP_Length decimationFactor = ceil(interpolationSmoothing * decimationCoefficient / inputGraphicPerDataPoint);
        vDSP_Length pointFillFactor = intendedFinalPoints/range.length;
        if (pointFillFactor > interpolationSmoothing && applySmoothing) {
            interpolationSmoothing = pointFillFactor * decimationFactor;
        }
        
        double *filter = malloc(decimationFactor * sizeof(double));
        double const filterValue = 1.0/decimationFactor;
        vDSP_vfillD(&filterValue, filter, 1, decimationFactor);
        
        vDSP_Length const decimateLen = (range.length - decimationFactor)/decimationFactor;
        double *decimated = malloc(decimateLen * sizeof(double));
        vDSP_desampD(vector + range.location, decimationFactor, filter, decimated, decimateLen, decimationFactor);
        free(filter);
        
        vDSP_Length const smoothedLen = decimateLen * interpolationSmoothing;
        double *smoothControl = malloc(smoothedLen * sizeof(double));
        double *smoothed = malloc(smoothedLen * sizeof(double));
        
        switch (technique) {
            case WSGraphSmoothingTechniqueLinear: {
                ws_vSmoothstepD(smoothControl, 1, decimateLen, smoothedLen);
                /*
                 * for (n = 0; n < N; ++n) {
                 *     float b = B[n*IB];
                 *     float index = trunc(b); // int part of B value
                 *     float alpha = b - index; // frac part of B value
                 *
                 *     float a0 = A[(int)index + 0]; // indexed A value
                 *     float a1 = A[(int)index + 1]; // next A value
                 *
                 *     C[n*IC] = a0 + (alpha * (a1 - a0)); // interpolated value
                 * }
                 */
                vDSP_vlintD(decimated, smoothControl, 1, smoothed, 1, smoothedLen, decimateLen);
            } break;
            case WSGraphSmoothingTechniqueQuadratic: {
                ws_vRampD(smoothControl, 1, decimateLen, smoothedLen);
                /*
                 * for (n = 0; n < N; ++n) {
                 *     float b = B[n*IB];
                 *     float index = max(trunc(b), 1);
                 *     float a = b - index;
                 *     float aSq = a**2;
                 *     C[n] = ( A[index-1] * (aSq - a) +
                 *              A[index+0] * (1 - aSq) * 2 +
                 *              A[index+1] * (aSq + a)
                 *            ) / 2;
                 * }
                 */
                vDSP_vqintD(decimated, smoothControl, 1, smoothed, 1, smoothedLen, decimateLen);
            } break;
            default: {
                assert(!applySmoothing);
                assert(smoothedLen == decimateLen);
                memcpy(smoothed, decimated, decimateLen * sizeof(double));
            } break;
        }
        
        free(decimated);
        free(smoothControl);
        
        _dataValues = smoothed;
        _indexFactor = (double)decimationFactor/interpolationSmoothing;
        _dataLength = smoothedLen;
        
        double minValue = 0, maxValue = 0;
        vDSP_minvD(smoothed, 1, &minValue, smoothedLen);
        vDSP_maxvD(smoothed, 1, &maxValue, smoothedLen);
        
        // avoid division by 0
        if ((maxValue == 0) && (minValue == 0)) {
            maxValue = +1;
            minValue = -1;
        } else if (fabs(maxValue - minValue) < DBL_EPSILON) {
            double const scale = 0.01;
            double const awayFromZero = (1 + scale);
            double const closerToZero = (1 - scale);
            
            maxValue *= (maxValue > 0) ? awayFromZero : closerToZero;
            minValue *= (minValue > 0) ? closerToZero : awayFromZero;
        }
        
        _minimumValue = minValue;
        _maximumValue = maxValue;
        
        _xScale = effectiveWidth / smoothedLen;
        _yScale = effectiveHeight / (maxValue - minValue);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (vDSP_Length idx = 0; idx < smoothedLen; idx++) {
            CGPoint point;
            point.x = [self _xForInternalIndex:idx];
            point.y = [self yValueForX:smoothed[idx]];
            if (idx == 0) {
                [path moveToPoint:point];
            } else {
                [path addLineToPoint:point];
            }
        }
        _path = path;
    }
    return self;
}

- (CGFloat)yValueForX:(double)x {
    x = MIN(x, self.maximumValue);
    x -= self.minimumValue;
    x = MAX(0, x);
#if TARGET_OS_IPHONE
    return self.size.height - self.insets.top - x*_yScale;
#else
    return x*_yScale + self.insets.bottom;
#endif
}
// index may be negative from `xForIndex:`
- (CGFloat)_xForInternalIndex:(NSInteger)index {
    return index * _xScale + _insets.left;
}
- (CGFloat)xForIndex:(NSUInteger)index {
    NSInteger slide = index - self.range.location;
    slide = ceil(slide / _indexFactor);
    return [self _xForInternalIndex:slide];
}

- (CGPoint)pointForIndex:(NSUInteger)index {
    NSRange range = self.range;
    NSParameterAssert(NSLocationInRange(index, range));
    
    index -= range.location;
    index = ceil(index / _indexFactor);
    index = MIN(index, _dataLength - 1);
    return CGPointMake([self _xForInternalIndex:index], [self yValueForX:_dataValues[index]]);
}

- (UIBezierPath *)circleForIndex:(NSUInteger)index radius:(CGFloat)radius {
    if (NSLocationInRange(index, self.range)) {
        CGPoint center = [self pointForIndex:index];
        return [UIBezierPath bezierPathWithCircleCenter:center radius:radius];
    }
    return NULL;
}

- (id)debugQuickLookObject {
#if TARGET_OS_IPHONE
    // path is in iOS coordinates. the result from
    // this method is sent to the connected Xcode
    // session, presumably on macOS (and we don't
    // currently have a convenient way of checking
    // the connected machine)
    // flip from iOS coordinate system to macOS
    
    /* * * * * * * * * * *         * * * * * * * * * * *
     * (0, 0)            *         *                   *
     *                   *         *                   *
     *                   *         *                   *
     *  iOS coordinates  *         * macOS coordinates *
     *                   *         *                   *
     *                   *         *                   *
     *                   *         * (0, 0)            *
     * * * * * * * * * * *         * * * * * * * * * * */
    
    UIBezierPath *pathCopy = [self.path copy];
    // Xcode shades in the region. Close the path along the border to avoid a diagonal shade
    CGFloat minY = [self yValueForX:self.minimumValue];
    NSRange range = self.range;
    [pathCopy addLineToPoint:CGPointMake([self xForIndex:NSRangeMaxIndex(range)], minY)];
    [pathCopy addLineToPoint:CGPointMake([self xForIndex:range.location], minY)];
    [pathCopy closePath];
    
    CGAffineTransform flip = CGAffineTransformMakeTranslation(0, CGRectGetMaxY(pathCopy.bounds));
    flip = CGAffineTransformScale(flip, 1, -1);
    /*
     * +1 +0 -0 -1
     * 0 height
     */
    [pathCopy applyTransform:flip];
    return pathCopy;
#else
    return self.path;
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; size = %@; range = %@; insets = %@; "
            "min = %f; max = %f>",
            [self class], self, NSStringFromCGSize(self.size), NSStringFromRange(self.range), NSStringFromUIEdgeInsets(self.insets),
            self.minimumValue, self.maximumValue];
}

- (void)dealloc {
    free((void *)_dataValues);
}

@end
