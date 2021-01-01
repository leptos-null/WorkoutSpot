//
//  WSDataAnalysis.h
//  WorkoutSpot
//
//  Created by Leptos on 6/18/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

#import "NSRange+WSIndex.h"
#import "WSGraphGuide.h"

/// Data Analysis provides a model to store and process
///   data points. The data is indexed by @c keys which
///   may represent indicies, or a relation to another
///   value such as time.
/// @discussion
/// An example may be altitude of an aircraft as @c data
///   and distance traveled as the @c keys (indicating
///   distance is the domain). The maximum would tell
///   you the highest the aircraft was. The minimum
///   would tell you the lowest the aircraft was.
///   If you take the derivative of this data, you get
///   the grade the aircraft was traveling on. The
///   maximum of the grade would tell you the steepest
///   grade at which the aircraft was climbing.
@interface WSDataAnalysis : NSObject

/// @discussion
/// The @c data and @c keys arrays should be related
///   such that @c data[n] corresponds to @c keys[n]
///   in the domain of @c keys
/// @param data An array of data of @c length
/// @param keys An array of keys of @c length
/// @param domain A value that descibes the magnitude
///   of the @c keys domain, such that the domain is @c [0, @c domain]
/// @param length The length of each of the input arrays
/// @note @c keys must increase monotonically
- (instancetype)initWithData:(const double *)data keys:(const double *)keys domain:(double)domain length:(const vDSP_Length)length;

/// The value at @c index
- (double)datumAtIndex:(NSUInteger)index;

/// The mean value over @c range
- (double)averageOverRange:(NSRange)range;
/// The maximum value over @c range
- (double)maximumOverRange:(NSRange)range;
/// The maximum value over @c range
- (double)minimumOverRange:(NSRange)range;
/// The difference between the value at
/// the beginning of @c range and the end
- (double)deltaOverRange:(NSRange)range;

/// Computes the instantaneous derivative of @c data
/// with respect to the domain.
/// The result has the same domain as the receiver.
/// @code
/// derivation[n + 0.5] = data[n + 1] - data[n]
/// @endcode
- (WSDataAnalysis *)derivative;
/// Computes the difference between @c data
/// @code
/// spacing[n] = data[n] - data[n - 1]
/// @endcode
- (WSDataAnalysis *)stepSpace;
/// Computes the compounded sum under the curve
/// @discussion
/// The inverse operation of @c stepSpace
- (WSDataAnalysis *)stairCase;

/// An analysis object where all the @c data are between @c lowerBound and @c upperBound
/// @discussion
/// Any datum below @c lowerBound will be replaced with such, and
///   any datum above @c upperBound will be replaced with such.
///   For example, the receiver represents the brightness of a room.
///   The @c data only contains illuminance from sunlight, but we would
///   like to consider a lightbulb is also in the room. Set the
///   @c lowerBound to the illuminance of the lightbulb, and @c upperBound
///   to @c INFINITY to effectively set a baseline value.
- (WSDataAnalysis *)clippingToLower:(double)lowerBound upper:(double)upperBound;

/// Computes the instantaneous derivative of @c data
/// with respect to @c dataDomain data.
/// @discussion
/// For example, the receiver is altitude in the time domain,
///   and @c dataDomain is distance in the time domain.
///   The derivative of altitude with respect to distance is grade.
///   This method is significantly more performant than the equivalent code
/// @code
/// WSDataAnalysis *converted = [dataAnalysis convertToDomain:dataDomain];
/// WSDataAnalysis *derivative = [converted derivative];
/// WSDataAnalysis *ret = [derivative convertToDomain:dataAnalysis];
/// @endcode
- (WSDataAnalysis *)derivativeInDomain:(WSDataAnalysis *)dataDomain;

/// The data of the receiver converted into the domain of @c dataDomain data.
/// @discussion
/// The domain of the receiver and @c dataDomain must be the same.
///   For example, the receiver is speed in the time domain, and
///   @c dataDomain is distance in the time domain. The result would
///   be speed in the distance domain.
- (WSDataAnalysis *)convertToDomain:(WSDataAnalysis *)dataDomain;

/// A graph guide that represents the data over @c range
- (WSGraphGuide *)graphGuideForConfiguration:(WSGraphConfiguration *)configuration;

@end


@interface WSDataAnalysis (WSAnalysisInternals)

/// Create a data analysis object with @c data that is increasing by @c 1 within the domain.
/// @discussion
/// @c data is stored by this object, and passed to @c free on @c dealloc
- (instancetype)initWithInterpolatedData:(const double *)data length:(vDSP_Length)length;

@property (nonatomic, readonly) const double *data NS_RETURNS_INNER_POINTER;
@property (nonatomic, readonly) vDSP_Length length;

@end
