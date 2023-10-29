//
//  WorkoutAnalysis.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/17/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import CoreLocation
import HealthKit
import Accelerate

final class WorkoutAnalysis {
    let timeDomain: KeyedWorkoutData
    let distanceDomain: KeyedWorkoutData
    
    init(rawWorkoutData: RawWorkoutData) {
        let timeDomain = KeyedWorkoutData(timeKey: rawWorkoutData)
        self.timeDomain = timeDomain
        self.distanceDomain = KeyedWorkoutData(rekey: timeDomain, by: \.distance)
    }
}

final class KeyedWorkoutData {
    let key: KeyPath<KeyedWorkoutData, ScalarSeries>
    
    let time: ScalarSeries
    let distance: ScalarSeries
    
    let altitude: ScalarSeries
    let coordinate: CoordinateSeries
    let speed: ScalarSeries
    
    let grade: ScalarSeries
    let ascending: ScalarSeries
    let descending: ScalarSeries
    
    let heartRate: ScalarSeries
    
    init(timeKey workoutData: RawWorkoutData) {
        let startDate = workoutData.workout.startDate
        let endDate = workoutData.workout.endDate
        
        let domainLength = Int(endDate.timeIntervalSince(startDate).rounded(.awayFromZero))
        
        var monotonicTime = UnsafeMutableBufferPointer<TimeInterval>.allocate(capacity: domainLength)
        vDSP.formRamp(withInitialValue: startDate.timeIntervalSinceReferenceDate, increment: 1, result: &monotonicTime)
        
        let locations = workoutData.locations
        let locationCount = locations.count
        
        let altitudeValues = UnsafeMutableBufferPointer<CLLocationDistance>.allocate(capacity: locationCount)
        let altitudeKeys = UnsafeMutableBufferPointer<TimeInterval>.allocate(capacity: locationCount)
        var altitudeCount = 0
        
        let coordinateValues = UnsafeMutableBufferPointer<CLLocationCoordinate2D>.allocate(capacity: locationCount)
        let coordinateKeys = UnsafeMutableBufferPointer<TimeInterval>.allocate(capacity: locationCount)
        var coordinateCount = 0
        
        for location in locations {
            let key = location.timestamp.timeIntervalSince(startDate)
            
            let altitude = location.altitude
            let coordinate = location.coordinate
            
            if location.verticalAccuracy >= 0 && altitude.isFinite {
                altitudeValues[altitudeCount] = altitude
                altitudeKeys[altitudeCount] = key
                altitudeCount += 1
            }
            
            if location.horizontalAccuracy >= 0 && CLLocationCoordinate2DIsValid(coordinate) {
                coordinateValues[coordinateCount] = coordinate
                coordinateKeys[coordinateCount] = key
                coordinateCount += 1
            }
        }
        
        let heartRates = workoutData.heartRates
        let heartRateCount = heartRates.count
        
        let heartRateValues = UnsafeMutableBufferPointer<Double>.allocate(capacity: heartRateCount)
        let heartRateKeys = UnsafeMutableBufferPointer<TimeInterval>.allocate(capacity: heartRateCount)
        
        for (index, heartRate) in heartRates.enumerated() {
            heartRateValues[index] = heartRate.quantity.doubleValue(for: .beatsPerSecond)
            heartRateKeys[index] = heartRate.startDate.timeIntervalSince(startDate)
        }
        
        let altitudeSeries = ScalarSeries(
            values: altitudeValues[0..<altitudeCount],
            keys: altitudeKeys[0..<altitudeCount],
            domainMagnitude: domainLength
        )
        let coordinateSeries = CoordinateSeries(
            values: coordinateValues[0..<coordinateCount],
            keys: coordinateKeys[0..<coordinateCount],
            domainMagnitude: domainLength
        )
        
        let heartRateSeries = ScalarSeries(
            values: heartRateValues,
            keys: heartRateKeys,
            domainMagnitude: domainLength
        )
        
        let distanceSeries = coordinateSeries.stepHeight().stairCase()
        
        let climbing = altitudeSeries.stepHeight()
        
        self.key = \.time
        
        self.time = ScalarSeries(raw: monotonicTime)
        self.distance = distanceSeries
        
        self.altitude = altitudeSeries
        self.coordinate = coordinateSeries
        self.speed = distanceSeries.derivative()
        
        self.grade = altitudeSeries.derivative(in: distanceSeries)
        self.ascending = climbing.clipping(to: 0...(+.infinity)).stairCase()
        self.descending = climbing.clipping(to: (-.infinity)...0).stairCase()
        
        self.heartRate = heartRateSeries
        
        heartRateValues.deallocate()
        heartRateKeys.deallocate()
        
        coordinateValues.deallocate()
        coordinateKeys.deallocate()
        
        altitudeValues.deallocate()
        altitudeKeys.deallocate()
    }
    
    init(rekey source: KeyedWorkoutData, by key: KeyPath<KeyedWorkoutData, ScalarSeries>) {
        let domainSeries = source[keyPath: key]
        
        let timeSeries = source.time.convert(to: domainSeries)
        let distanceSeries = source.distance.convert(to: domainSeries)
        let altitudeSeries = source.altitude.convert(to: domainSeries)
        
        let climbing = altitudeSeries.stepHeight()
        
        self.key = key
        
        self.time = timeSeries
        self.distance = distanceSeries
        
        self.altitude = altitudeSeries
        self.coordinate = source.coordinate.convert(to: domainSeries)
        self.speed = distanceSeries.derivative(in: timeSeries)
        
        self.grade = altitudeSeries.derivative(in: distanceSeries)
        self.ascending = climbing.clipping(to: 0...(+.infinity)).stairCase()
        self.descending = climbing.clipping(to: (-.infinity)...0).stairCase()
        
        self.heartRate = source.heartRate.convert(to: domainSeries)
    }
}

extension KeyedWorkoutData {
    var keySeries: ScalarSeries { self[keyPath: key] }
}

extension KeyedWorkoutData: RandomAccessCollection {
    typealias Index = Int
    typealias Indices = Range<Index>
    
    @dynamicMemberLookup
    struct Element {
        let base: KeyedWorkoutData
        let index: KeyedWorkoutData.Index
        
        subscript<T: RandomAccessCollection>(dynamicMember member: KeyPath<KeyedWorkoutData, T>) -> T.Element where T.Index == KeyedWorkoutData.Index {
            let series = base[keyPath: member]
            return series[index]
        }
    }
    
    @dynamicMemberLookup
    struct SubSequence: RandomAccessCollection {
        typealias Element = KeyedWorkoutData.Element
        typealias Index = KeyedWorkoutData.Index
        
        let base: KeyedWorkoutData
        let indices: KeyedWorkoutData.Indices
        
        subscript<T: RandomAccessCollection>(dynamicMember member: KeyPath<KeyedWorkoutData, T>) -> T.SubSequence where T.Indices == KeyedWorkoutData.Indices {
            let series = base[keyPath: member]
            return series[indices]
        }
        
        var startIndex: KeyedWorkoutData.Index { indices.lowerBound }
        var endIndex: KeyedWorkoutData.Index { indices.upperBound }
        
        subscript(position: Index) -> Element {
            base[position]
        }
        
        subscript(bounds: KeyedWorkoutData.Indices) -> Self {
            base[bounds]
        }
        
        // since `SubSequence` conforms to `RandomAccessCollection`,
        // `distance` is confused with the function `distance(from:to:)`
        var distance: ScalarSeries.SubSequence {
            base.distance[indices]
        }
    }
    
    subscript(position: Index) -> Element {
        Element(base: self, index: position)
    }
    
    subscript(bounds: Indices) -> SubSequence {
        SubSequence(base: self, indices: bounds)
    }
    
    private var representativeSeries: ScalarSeries { time }
    
    var startIndex: Index { representativeSeries.startIndex }
    var endIndex: Index { representativeSeries.endIndex }
    var indices: Indices { representativeSeries.indices }
    var count: Int { representativeSeries.count }
}

extension KeyedWorkoutData {
    /// Select an index that may be a valid index or equal to `endIndex`
    func bestHalfOpenIndex<F: BinaryFloatingPoint>(for floatingIndex: F) -> Index {
        let nearestIndex = Index(floatingIndex.rounded())
        return Swift.max(startIndex, Swift.min(nearestIndex, endIndex))
    }
    
    /// Select a valid index that best represents `floatingIndex`
    func bestClosedIndex<F: BinaryFloatingPoint>(for floatingIndex: F) -> Index {
        guard let firstIndex = indices.first,
              let lastIndex = indices.last else {
            fatalError("Empty collection")
        }
        
        let nearestIndex = Index(floatingIndex.rounded())
        return Swift.max(firstIndex, Swift.min(nearestIndex, lastIndex))
    }
    /// Select a valid index that represents `percent`
    ///
    /// `0` would return the first valid index and
    /// `1` would return the last valid index
    func indexForPercent<F: BinaryFloatingPoint>(_ percent: F) -> Index {
        let floatingCount = F(count)
        return bestClosedIndex(for: percent * floatingCount)
    }
    /// Select the index that best represents `source[index]`
    func convertIndex(_ index: Index, from source: KeyedWorkoutData) -> Index {
        let unit = self[keyPath: key]
        let query = source[keyPath: key]
        
        let offset = query[index]
        let base = unit[0]
        
        return bestClosedIndex(for: offset - base)
    }
    /// Select the range that best represents `source[range]`
    func convertRange(_ range: Range<Index>, from source: KeyedWorkoutData) -> Range<Index> {
        // use first and last because it's more accurate.
        // we can't call `convertIndex` with `upperBound` because it could be out of bounds.
        // `upperBound` could also represent a very different point from `last`; e.g. the indices
        // on either side of a pause segment in a workout.
        guard let firstIndex = range.first,
              let lastIndex = range.last else {
            let lowerBound = convertIndex(range.lowerBound, from: source)
            return lowerBound..<lowerBound // we got an empty range, return an empty range
        }
        
        let lowerBound = convertIndex(firstIndex, from: source)
        let upperBound = convertIndex(lastIndex, from: source)
        return Range(lowerBound...upperBound)
    }
    /// Convenience function to get the subsequence that best represents `source[range]`
    func subSequence(converting range: Range<Index>, from source: KeyedWorkoutData) -> SubSequence {
        let range = convertRange(range, from: source)
        return self[range]
    }
}

extension HKUnit {
    static let beatsPerSecond = HKUnit.count().unitDivided(by: .second())
}
