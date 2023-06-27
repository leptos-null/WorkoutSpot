//
//  WorkoutSegmentStatsView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/27/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI

struct WorkoutSegmentStatsView: View {
    let stats: KeyedWorkoutData.SubSequence
    
    var body: some View {
        VStack(alignment: .leading) {
            TitleValueInlineView(title: "Duration") {
                Text(
                    Date(timeIntervalSinceReferenceDate: stats.time.first!)..<Date(timeIntervalSinceReferenceDate: stats.time.last!),
                    format: .components(style: .abbreviated)
                )
            }
            .foregroundStyle(Color(uiColor: .workoutSegment))
            
            TitleValueInlineView(title: "Distance") {
                Text(
                    Measurement(value: stats.base.distance[stats.indices].delta(), unit: UnitLength.meters),
                    format: .measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .workoutSegment))
            
            TitleValueInlineView(title: "Climbing") {
                Text(
                    Measurement(value: stats.ascending.delta(), unit: UnitLength.meters),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .altitude))
            
            TitleValueInlineView(title: "Avg. Grade") {
                Text(
                    stats.grade.average(),
                    format: .percent.precision(.fractionLength(2))
                )
            }
            .foregroundStyle(Color(uiColor: .workoutSegment))
            
            TitleValueInlineView(title: "Avg. Speed") {
                Text(
                    Measurement(value: stats.speed.average(), unit: UnitSpeed.metersPerSecond),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .speed))
            
            TitleValueInlineView(title: "Avg. Heart Rate") {
                Text(
                    Measurement(value: stats.heartRate.average(), unit: UnitFrequency.hertz),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .heartRate))
        }
    }
}
