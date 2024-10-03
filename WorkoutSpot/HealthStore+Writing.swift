//
//  HealthStore+Writing.swift
//  WorkoutSpot
//
//  Created by Leptos on 10/1/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import Foundation
import HealthKit

extension HealthStore {
    func write(workoutData: RawWorkoutData) async throws {
        let workout = workoutData.workout
        
        let config = HKWorkoutConfiguration()
        config.activityType = workout.workoutActivityType
        if let workoutMetadata = workout.metadata {
            if let isIndoor = workoutMetadata[HKMetadataKeyIndoorWorkout] as? Bool {
                config.locationType = isIndoor ? .indoor : .outdoor
            }
            if let rawSwimLocation = workoutMetadata[HKMetadataKeySwimmingLocationType] as? HKWorkoutSwimmingLocationType.RawValue,
               let swimLocation = HKWorkoutSwimmingLocationType(rawValue: rawSwimLocation) {
                config.swimmingLocationType = swimLocation
            }
            if let lapLength = workoutMetadata[HKMetadataKeyLapLength] as? HKQuantity {
                config.lapLength = lapLength
            }
        }
        
        let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: workout.device)
        
        func pushDiscreteQuantitySamples(_ samples: [HKDiscreteQuantitySample]) async throws {
            // both of these APIs require `samples` to not be empty
            if samples.isEmpty { return }
            // in my testing, if we don't create a copy, the sample doesn't save
            let copies = samples.map {
                HKDiscreteQuantitySample(
                    type: $0.quantityType, quantity: $0.quantity,
                    start: $0.startDate, end: $0.endDate,
                    device: $0.device, metadata: $0.metadata
                )
            }
            try await healthStore.save(copies)
            try await workoutBuilder.addSamples(copies)
        }
        
        try await workoutBuilder.beginCollection(at: workout.startDate)
        try await pushDiscreteQuantitySamples(workoutData.heartRates)
        try await pushDiscreteQuantitySamples(workoutData.runningPower)
        try await pushDiscreteQuantitySamples(workoutData.cyclingPower)
        try await workoutBuilder.endCollection(at: workout.endDate)
        
        guard let newWorkout = try await workoutBuilder.finishWorkout() else {
            throw HKError(.unknownError)
        }
        
        // the device and metadata information is stored in HKWorkoutRoute,
        // which is not preserved in RawWorkoutData
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        
        try await routeBuilder.insertRouteData(workoutData.locations)
        try await routeBuilder.finishRoute(with: newWorkout, metadata: nil)
    }
}
