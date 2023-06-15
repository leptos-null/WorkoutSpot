//
//  WorkoutObserver.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import HealthKit

final class WorkoutObserver: ObservableObject {
    // sorted descending by start date
    @Published private(set) var workouts: [HKWorkout]?
    
    let healthStore: HKHealthStore
    
    private var activeQuery: HKQuery? {
        willSet {
            if let oldValue = activeQuery {
                healthStore.stop(oldValue)
            }
        }
        didSet {
            if let newValue = activeQuery {
                healthStore.execute(newValue)
            }
        }
    }
    
    private var workoutLookup: [UUID: HKWorkout] = [:]
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    func workout(for uuid: UUID) -> HKWorkout? {
        workoutLookup[uuid]
    }
    
    func prefetch(limit: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // there's already been a fetch, don't overwrite with prefetch data
        guard workouts == nil else {
            completion?(.success(()))
            return
        }
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: nil, limit: limit,
            sortDescriptors: [ NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false) ]
        ) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error {
                    completion?(.failure(error))
                    return
                }
                guard let self,
                      let workouts = samples as? [HKWorkout] else {
                    // not really a success, but we don't want to do anything
                    completion?(.success(()))
                    return
                }
                self.workouts = workouts
                self.workoutLookup = workouts.reduce(into: [:]) { partialResult, workout in
                    partialResult[workout.uuid] = workout
                }
                completion?(.success(()))
            }
        }
        self.activeQuery = query
    }
    
    func prefetch(limit: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            prefetch(limit: limit, completion: continuation.resume(with:))
        }
    }
    
    func streamUpdates(initialCompletion: (() -> Void)? = nil) {
        var completion = initialCompletion
        var localWorkouts: [HKWorkout] = []
        var localLookup: [UUID: HKWorkout] = [:]
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] query, samples, deletes, anchor, error in
            DispatchQueue.main.async {
                if let error {
                    //
                    return
                }
                guard let self else { return }
                
                if let workouts = samples as? [HKWorkout] {
                    for workout in workouts {
                        localLookup[workout.uuid] = workout
                    }
                    
                    let sortComparator = KeyPathComparator<HKWorkout>(\.startDate, order: .reverse)
                    let sortedDelta = workouts.sorted(using: sortComparator)
                    localWorkouts = .sortedMerge(localWorkouts, sortedDelta, using: sortComparator)
                }
                
                if let deletes {
                    // the goal of this operation is as follows:
                    //   `localWorkouts` contains `n` items
                    //   `deletes` contains `m` items
                    //   for every item in `deletes`,
                    //     we must remove the corresponding item in `localWorkouts`
                    //   the common solution would take nm time.
                    //   to avoid this, we'll add all the `deletes` items to a set (m time),
                    //   then remove items from `localWorkouts` based on the set (n log(m) time)
                    var removedUUIDs: Set<UUID> = []
                    
                    // two unrelated operations
                    for delete in deletes {
                        // first remove the object from the lookup dictionary
                        localLookup.removeValue(forKey: delete.uuid)
                        // then add to removedUUIDs
                        removedUUIDs.insert(delete.uuid)
                    }
                    
                    // additional optimization:
                    //   use `remove` instead of `contains` so that `removedUUIDs` gets smaller
                    //   since we assume that each UUID in `localWorkouts` may only occur once
                    localWorkouts.removeAll { workout in
                        removedUUIDs.remove(workout.uuid) != nil
                    }
                }
                
                self.workouts = localWorkouts
                self.workoutLookup = localLookup
                completion?()
                completion = nil
            }
        }
        let query = HKAnchoredObjectQuery(type: .workoutType(), predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        self.activeQuery = query
    }
}
