//
//  HealthStore.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import HealthKit

final class HealthStore {
    let healthStore = HKHealthStore()
    
    // all sample types used throughout the app.
    // request all up front so that we don't show the
    // authorization screen multiple times in a short spane
    static let sampleTypes: Set<HKSampleType> = [
        HKWorkoutType.workoutType(),
        HKQuantityType(.heartRate),
        HKSeriesType.workoutRoute()
    ]
    
    func requestReadAuthorizationIfNeeded() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: Self.sampleTypes)
    }
}
