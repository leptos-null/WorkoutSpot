//
//  NSRange+WSIndex.h
//  WorkoutSpot
//
//  Created by Leptos on 7/9/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/NSRange.h>

/// The maximum index within the range.
/// One less than the length plus the location
NS_INLINE NSUInteger NSRangeMaxIndex(NSRange range) {
    return NSMaxRange(range) - 1;
}
/// Creates a new @c NSRange with the indicies [startIndex, finalIndex]
NS_INLINE NSRange NSRangeMakeInclusive(NSUInteger startIndex, NSUInteger finalIndex) {
    return NSMakeRange(startIndex, finalIndex - startIndex + 1);
}
