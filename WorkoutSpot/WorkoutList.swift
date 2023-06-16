//
//  WorkoutList.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI
import HealthKit

private struct DayWorkouts {
    let date: Date
    
    var workouts: [HKWorkout]
}

extension DayWorkouts: Identifiable {
    var id: Date { date }
}

struct WorkoutList: View {
    let healthStore: HealthStore
    
    @State private var selection: HKWorkout.ID?
    @State private var trailFetchInFlight = false
    
    @StateObject private var workoutSource: WorkoutObserver
    
    @Environment(\.calendar) private var calendar
    
    init(healthStore: HealthStore) {
        self.healthStore = healthStore
        _workoutSource = StateObject(wrappedValue: WorkoutObserver(healthStore: healthStore.healthStore))
    }
    
    private var datedWorkouts: [DayWorkouts]? {
        guard let workouts = workoutSource.workouts else { return nil }
        
        return workouts.reduce(into: []) { partialResult, workout in
            if let last = partialResult.last,
               calendar.isDate(workout.startDate, inSameDayAs: last.date) {
                let lastIndex = partialResult.index(before: partialResult.endIndex)
                partialResult[lastIndex].workouts.append(workout)
            } else {
                partialResult.append(DayWorkouts(date: workout.startDate, workouts: [workout]))
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            if let datedWorkouts {
                List(selection: $selection) {
                    ForEach(datedWorkouts) { staple in
                        Section {
                            ForEach(staple.workouts) { workout in
                                WorkoutCell(workout: workout)
                            }
                        } header: {
                            Text(staple.date, style: .date)
                                .font(.title3)
                        }
                    }
                    if trailFetchInFlight {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Workouts")
                .refreshable {
                    await withCheckedContinuation { continuation in
                        workoutSource.streamUpdates(initialCompletion: continuation.resume)
                    }
                }
            } else {
                ProgressView()
            }
        } detail: {
            if let selection, let workout = workoutSource.workout(for: selection) {
                WorkoutDetail(workout: workout)
            } else {
                Text("Select a workout from the sidebar")
            }
        }
        .task {
            // TODO
            try! await healthStore.requestReadAuthorizationIfNeeded()
            try! await workoutSource.prefetch(limit: 20)
            self.trailFetchInFlight = true
            workoutSource.streamUpdates {
                trailFetchInFlight = false
            }
        }
    }
}

struct WorkoutCell: View {
    let workout: HKWorkout
    
    private var dateRange: Range<Date> {
        workout.startDate..<workout.endDate
    }
    
    var body: some View {
        HStack {
            Image(systemName: workout.workoutActivityType.systemImageName ?? "heart")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.debugDescription) // TODO
                    .font(.body)
                Text(dateRange, format: Date.IntervalFormatStyle(date: .omitted, time: .standard))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(dateRange, format: .components(style: .condensedAbbreviated))
                    .font(.headline)
            }
        }
    }
}

struct WorkoutDetail: View {
    let workout: HKWorkout
    
    var body: some View {
        Text(verbatim: "TODO")
    }
}

extension HKObject: Identifiable {
    public var id: UUID { uuid }
}
