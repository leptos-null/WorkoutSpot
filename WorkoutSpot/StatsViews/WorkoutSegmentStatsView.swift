//
//  WorkoutSegmentStatsView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/27/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI

extension KeyedWorkoutData.SubSequence {
    var dateRange: Range<Date>? {
        guard let timeSeries = self.time,
              let first = timeSeries.first,
              let last = timeSeries.last else { return nil }
        let start = Date(timeIntervalSinceReferenceDate: first)
        let end = Date(timeIntervalSinceReferenceDate: last)
        return start..<end
    }
}

struct WorkoutSegmentStatsView: View {
    @ObservedObject var viewModel: KeyedWorkoutViewModel
    
    let stats: KeyedWorkoutData.SubSequence
    
    @StateObject private var unitPreferences: UnitPreferences = .shared
    
    // Averages of derivates are only valid in the domain they're taken with respect to.
    // For example, speed is the derivative of distance with respect to time; the average
    // value of the speed series is only valid in the time domain.
    let timeStats: KeyedWorkoutData.SubSequence
    
    init(viewModel: KeyedWorkoutViewModel) {
        self.viewModel = viewModel
        
        let selectionRange = viewModel.selectionRange
        let keyedData = viewModel.keyedData
        
        let stats = keyedData[selectionRange]
        self.stats = stats
        self.timeStats = (viewModel.analysis.timeDomain === keyedData)
            ? stats
            : viewModel.analysis.timeDomain.subSequence(converting: selectionRange, from: keyedData)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let dateRange = stats.dateRange {
                TitleValueInlineView(title: "Duration") {
                    Text(
                        dateRange,
                        format: .components(style: .abbreviated)
                    )
                }
                .foregroundStyle(Color(uiColor: .workoutSegment))
            }
            
            if let distance = stats.distance {
                TitleValueInlineView(title: "Distance") {
                    Text.meters(distance.delta(), width: .abbreviated, unit: unitPreferences.distanceUnit)
                }
                .foregroundStyle(Color(uiColor: .workoutSegment))
            }
            
            if let ascending = stats.ascending {
                TitleValueInlineView(title: "Climbing") {
                    Text.meters(ascending.delta(), width: .abbreviated, unit: unitPreferences.altitudeUnit)
                }
                .foregroundStyle(Color(uiColor: .altitude))
            }
            
            if let altitude = stats.altitude, let distance = stats.distance {
                TitleValueInlineView(title: "Avg. Grade", accessibilityLabel: "Average Grade") {
                    Text(
                        altitude.delta() / distance.delta(),
                        format: .percent.precision(.fractionLength(2))
                    )
                }
                .foregroundStyle(Color(uiColor: .workoutSegment))
            }
            
            if let distance = stats.distance, let time = stats.time {
                TitleValueInlineView(title: "Avg. Speed", accessibilityLabel: "Average Speed") {
                    Text.metersPerSecond(distance.delta() / time.delta(), width: .abbreviated, unit: unitPreferences.speedUnit)
                }
                .foregroundStyle(Color(uiColor: .speed))
            }
            
            if let heartRate = timeStats.heartRate {
                TitleValueInlineView(title: "Avg. ♥ Rate", accessibilityLabel: "Average Heart Rate") {
                    Text.beatsPerSecond(heartRate.average(), width: .abbreviated)
                }
                .foregroundStyle(Color(uiColor: .heartRate))
            }
            if let runningPower = timeStats.runningPower {
                TitleValueInlineView(title: "Avg. Power", accessibilityLabel: "Average Power") {
                    Text(watts: runningPower.average(), width: .abbreviated)
                }
                .foregroundStyle(Color(uiColor: .runningPower))
            }
        }
    }
}
