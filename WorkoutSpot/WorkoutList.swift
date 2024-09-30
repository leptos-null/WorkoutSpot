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
    
    @State private var healthAuthError: Error?
    @State private var prefetchError: Error?
    
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
                VStack {
                    if let healthAuthError {
                        ErrorBulletinView("An error occurred getting HealthKit authorization.", error: healthAuthError)
                    }
                    if let fetchError = prefetchError ?? workoutSource.error {
                        ErrorBulletinView("An error occurred fetching workouts.", error: fetchError)
                    }
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
                }
            } else {
                ProgressView()
            }
        } detail: {
            if let selection, let workout = workoutSource.workout(for: selection) {
                WorkoutDetail(workout: workout, healthStore: healthStore)
                    .navigationTitle(workout.workoutActivityType.debugDescription) // TODO: user facing string
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Select a workout from the sidebar")
            }
        }
        .task {
            do {
                try await healthStore.requestReadAuthorizationIfNeeded()
            } catch {
                self.healthAuthError = error
                // don't return, maybe we can still read some data
            }
            do {
                try await workoutSource.prefetch(limit: 20)
            } catch {
                self.prefetchError = error
                return
            }
            self.trailFetchInFlight = true
            workoutSource.streamUpdates {
                trailFetchInFlight = false
            }
        }
    }
}

struct ErrorBulletinView<S: StringProtocol>: View {
    let title: S
    let error: Error
    
    init(_ title: S, error: Error) {
        self.title = title
        self.error = error
    }
    
    var body: some View {
        VStack {
            Label(title, systemImage: "exclamationmark.triangle")
            Text(error.localizedDescription)
        }
        .padding(12)
        .background(Color.red, in: RoundedRectangle(cornerRadius: 8))
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
                Text(workout.workoutActivityType.debugDescription) // TODO: user facing string
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

final class WorkoutDetailViewModel: ObservableObject {
    @Published private(set) var analysis: Result<WorkoutAnalysis, Error>?
    
    func update(for workout: HKWorkout, healthStore: HealthStore) async {
        let result: Result<WorkoutAnalysis, Error>
        do {
            let workoutData = try await healthStore.rawWorkoutData(for: workout)
            let analysis = WorkoutAnalysis(rawWorkoutData: workoutData)
            result = .success(analysis)
        } catch {
            result = .failure(error)
        }
        
        await MainActor.run {
            self.analysis = result
        }
    }
}

struct WorkoutDetail: View {
    @StateObject private var viewModel = WorkoutDetailViewModel()
    
    let workout: HKWorkout
    let healthStore: HealthStore
    
    var body: some View {
        if let result = viewModel.analysis {
            Group {
                switch result {
                case .success(let analysis):
                    KeyedWorkoutView(viewModel: .init(analysis: analysis))
                case .failure(let error):
                    ErrorBulletinView("An error occurred fetching data for this workout.", error: error)
                }
            }
            .onChange(of: workout) { newValue in
                Task {
                    await viewModel.update(for: newValue, healthStore: healthStore)
                }
            }
        } else {
            ProgressView()
                .task {
                    await viewModel.update(for: workout, healthStore: healthStore)
                }
        }
    }
}

extension HKObject: @retroactive Identifiable {
    public var id: UUID { uuid }
}
