//
//  WSGraphGuide.m
//  WorkoutSpot
//
//  Created by Leptos on 6/6/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSGraphGuide.h"
#import "UIBezierPath+WSCenteredCircle.h"
#import "NSRange+WSIndex.h"

@implementation WSGraphGuide {
    const double *_decimatedData;
    vDSP_Length _decimationFactor;
    vDSP_Length _decimatedLength;
    
    CGFloat _xScale;
    CGFloat _yScale;
}

- (instancetype)initWithVector:(const double *)vector configuration:(WSGraphConfiguration *)config {
    NSRange const range = config.range;
    CGSize const size = config.size;
    UIEdgeInsets const insets = config.edgeInsets;
    
    if (range.length == 0 || size.width <= 0) {
        return nil;
    }
    if (self = [super init]) {
        _size = size;
        _insets = insets;
        _range = range;
        
        CGFloat const effectiveWidth = size.width - (insets.left + insets.right);
        CGFloat const effectiveHeight = size.height - (insets.bottom + insets.top);
        
        double decimationCoefficient = 3; // a value chosen to improve graph smoothing
        vDSP_Length const decimationFactor = ceil(decimationCoefficient * range.length/effectiveWidth);
        
        double *filter = malloc(decimationFactor * sizeof(double));
        double const filterValue = 1.0/decimationFactor;
        vDSP_vfillD(&filterValue, filter, 1, decimationFactor);
        
        vDSP_Length const decimateLen = (range.length - decimationFactor)/decimationFactor;
        double *decimated = malloc(decimateLen * sizeof(double));
        vDSP_desampD(vector + range.location, decimationFactor, filter, decimated, decimateLen, decimationFactor);
        free(filter);
        
        _decimatedData = decimated;
        _decimationFactor = decimationFactor;
        _decimatedLength = decimateLen;
        
        double minValue = 0, maxValue = 0;
        
        vDSP_minvD(decimated, 1, &minValue, decimateLen);
        vDSP_maxvD(decimated, 1, &maxValue, decimateLen);
        
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
        
        _xScale = effectiveWidth / decimateLen;
        _yScale = effectiveHeight / (maxValue - minValue);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (vDSP_Length idx = 0; idx < decimateLen; idx++) {
            CGPoint point;
            point.x = [self _xForInternalIndex:idx];
            point.y = [self yForDatum:decimated[idx]];
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

- (CGFloat)yForDatum:(double)x {
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
    slide /= (NSInteger)_decimationFactor;
    return [self _xForInternalIndex:slide];
}

- (CGPoint)pointForIndex:(NSUInteger)index {
    NSRange range = self.range;
    NSParameterAssert(NSLocationInRange(index, range));
    
    index -= range.location;
    index /= (NSInteger)_decimationFactor;
    index = MIN(index, _decimatedLength - 1);
    return CGPointMake([self _xForInternalIndex:index], [self yForDatum:_decimatedData[index]]);
}

- (UIBezierPath *)circleForIndex:(NSUInteger)index radius:(CGFloat)radius {
    if (NSLocationInRange(index, self.range)) {
        CGPoint center = [self pointForIndex:index];
        return [UIBezierPath bezierPathWithCircleCenter:center radius:radius];
    }
    return NULL;
}

- (id)debugQuickLookObject {
    UIBezierPath *pathCopy = [self.path copy];
    // Xcode shades in the region. Close the path along the border to avoid a diagonal shade
    CGFloat minY = [self yForDatum:self.minimumValue];
    NSRange range = self.range;
    [pathCopy addLineToPoint:CGPointMake([self xForIndex:NSRangeMaxIndex(range)], minY)];
    [pathCopy addLineToPoint:CGPointMake([self xForIndex:NSRangeMinIndex(range)], minY)];
    [pathCopy closePath];
    
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
    
    CGAffineTransform flip = CGAffineTransformMakeTranslation(0, CGRectGetMaxY(pathCopy.bounds));
    flip = CGAffineTransformScale(flip, 1, -1);
    /*
     * +1 +0 -0 -1
     * 0 height
     */
    [pathCopy applyTransform:flip];
#endif
    return pathCopy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; size = %@; range = %@; insets = %@; "
            "min = %f; max = %f>",
            [self class], self, NSStringFromCGSize(self.size), NSStringFromRange(self.range), NSStringFromUIEdgeInsets(self.insets),
            self.minimumValue, self.maximumValue];
}

- (void)dealloc {
    free((void *)_decimatedData);
}

@end
