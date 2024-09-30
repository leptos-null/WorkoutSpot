//
//  HealthStore.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation

final class HealthStore {
    let healthStore = HKHealthStore()
    
    // all sample types used throughout the app.
    // request all up front so that we don't show the
    // authorization screen multiple times in a short spane
    static let sampleTypes: Set<HKSampleType> = [
        HKWorkoutType.workoutType(),
        HKQuantityType(.heartRate),
        HKSeriesType.workoutRoute(),
        HKQuantityType(.runningPower),
    ]
    
    func requestReadAuthorizationIfNeeded() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: Self.sampleTypes)
    }
    
    private func queryQuantitySeries(quantityType: HKQuantityType, predicate: NSPredicate?) async throws -> [HKDiscreteQuantitySample] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKDiscreteQuantitySample], Error>) in
            var collected: [HKDiscreteQuantitySample] = []
            let query = HKQuantitySeriesSampleQuery(quantityType: quantityType, predicate: predicate) { query, quantity, dateInterval, _, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let quantity, let dateInterval {
                    let sample = HKDiscreteQuantitySample(
                        type: quantityType, quantity: quantity,
                        start: dateInterval.start, end: dateInterval.end
                    )
                    collected.append(sample)
                }
                if done {
                    continuation.resume(returning: collected)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func locations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
            var collected: [CLLocation] = []
            let query = HKWorkoutRouteQuery(route: route) { query, locations, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let locations else {
                    // per https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/reading_route_data
                    fatalError("locations may not be nil if error is non-nil")
                }
                collected.append(contentsOf: locations)
                
                if done {
                    continuation.resume(returning: collected)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func queryWorkoutRoute(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
            let query = HKSampleQuery(
                sampleType: HKSeriesType.workoutRoute(), predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: sortDescriptors
            ) { query, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let routes = samples as? [HKWorkoutRoute] else {
                    assertionFailure("samples is unexpected type")
                    return
                }
                Task {
                    do {
                        let result = try await withThrowingTaskGroup(of: (index: Int, locations: [CLLocation]).self) { group in
                            for (index, route) in routes.enumerated() {
                                group.addTask {
                                    let result = try await self.locations(for: route)
                                    return (index, result)
                                }
                            }
                            // preserve the order of routes, which should be sorted
                            let collect = Array<[CLLocation]>(repeating: [], count: routes.count)
                            return try await group
                                .reduce(into: collect) { partialResult, item in
                                    partialResult[item.index] = item.locations
                                }
                                .flatMap { $0 }
                        }
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            healthStore.execute(query)
        }
    }
    
    func rawWorkoutData(for workout: HKWorkout) async throws -> RawWorkoutData {
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let heartRateType = HKQuantityType(.heartRate)
        // "HealthKit returns quantities in ascending order, based on their start date"
        async let heartRatePromise = queryQuantitySeries(quantityType: heartRateType, predicate: predicate)

        let runningPowerType = HKQuantityType(.runningPower)
        // "HealthKit returns quantities in ascending order, based on their start date"
        async let runningPowerPromise = queryQuantitySeries(quantityType: runningPowerType, predicate: predicate)

        async let locationsPromise = queryWorkoutRoute(predicate: predicate, sortDescriptors: [
            NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        ])
        
        return RawWorkoutData(
            workout: workout,
            locations: try await locationsPromise,
            heartRates: try await heartRatePromise,
            runningPower: try await runningPowerPromise
        )
    }
}

final class RawWorkoutData {
    let workout: HKWorkout
    
    let locations: [CLLocation]
    let heartRates: [HKDiscreteQuantitySample]
    let runningPower: [HKDiscreteQuantitySample]

    init(workout: HKWorkout, locations: [CLLocation], heartRates: [HKDiscreteQuantitySample], runningPower: [HKDiscreteQuantitySample]) {
        self.workout = workout
        self.locations = locations
        self.heartRates = heartRates
        self.runningPower = runningPower
    }
}

extension NSPredicate: @retroactive @unchecked Sendable {
    
}
