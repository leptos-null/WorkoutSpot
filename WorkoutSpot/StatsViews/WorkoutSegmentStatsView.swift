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
                    Text(
                        Measurement(value: distance.delta(), unit: UnitLength.meters),
                        format: .measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .workoutSegment))
            }
            
            if let ascending = stats.ascending {
                TitleValueInlineView(title: "Climbing") {
                    Text(
                        Measurement(value: ascending.delta(), unit: UnitLength.meters),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .altitude))
            }
            
            if let altitude = stats.altitude, let distance = stats.distance {
                TitleValueInlineView(title: "Avg. Grade") {
                    Text(
                        altitude.delta() / distance.delta(),
                        format: .percent.precision(.fractionLength(2))
                    )
                }
                .foregroundStyle(Color(uiColor: .workoutSegment))
            }
            
            if let distance = stats.distance, let time = stats.time {
                TitleValueInlineView(title: "Avg. Speed") {
                    Text(
                        Measurement(value: distance.delta() / time.delta(), unit: UnitSpeed.metersPerSecond),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .speed))
            }
            
            if let heartRate = timeStats.heartRate {
                TitleValueInlineView(title: "Avg. Heart Rate") {
                    Text(
                        Measurement(value: heartRate.average(), unit: UnitFrequency.hertz),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .heartRate))
            }
        }
    }
}
