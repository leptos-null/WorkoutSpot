//
//  NSRange+WSIndex.h
//  WorkoutSpot
//
//  Created by Leptos on 7/9/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/NSRange.h>

/// The minimum index within the range.
/// Equivalent to the location
NS_INLINE NSUInteger NSRangeMinIndex(NSRange range) {
    return range.location;
}
/// The maximum index within the range.
/// One less than the length plus the location
NS_INLINE NSUInteger NSRangeMaxIndex(NSRange range) {
    return NSMaxRange(range) - 1;
}
/// Creates a new @c NSRange with the indicies [startIndex, finalIndex]
NS_INLINE NSRange NSRangeMakeInclusive(NSUInteger startIndex, NSUInteger finalIndex) {
    return NSMakeRange(startIndex, finalIndex - startIndex + 1);
}
/// The closest value to @c indx within @c range
NS_INLINE NSUInteger NSRangeClampIndex(NSUInteger indx, NSRange range) {
    NSUInteger min = NSRangeMinIndex(range);
    if (indx < min) {
        return min;
    }
    NSUInteger max = NSRangeMaxIndex(range);
    if (indx > max) {
        return max;
    }
    return indx;
}
