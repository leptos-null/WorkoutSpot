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
    private func bestIndex<F: BinaryFloatingPoint>(for floatingIndex: F) -> Int {
        guard let firstIndex = time.indices.first,
              let lastIndex = time.indices.last else {
            return 0
        }
        
        let nearestIndex = Int(floatingIndex.rounded())
        return max(firstIndex, min(nearestIndex, lastIndex))
    }
    
    func indexForPercent<F: BinaryFloatingPoint>(_ percent: F) -> Int {
        let floatingCount = F(time.count)
        return bestIndex(for: percent * floatingCount)
    }
    
    func convertIndex(_ index: Int, from source: KeyedWorkoutData) -> Int {
        let unit = self[keyPath: key]
        let query = source[keyPath: key]
        
        let offset = query[index]
        let base = unit[0]
        
        return bestIndex(for: offset - base)
    }
}

extension HKUnit {
    static let beatsPerSecond = HKUnit.count().unitDivided(by: .second())
}
