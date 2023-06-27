//
//  WorkoutPointStatsView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/27/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI

struct WorkoutPointStatsView: View {
    let stats: KeyedWorkoutData.Element
    
    var body: some View {
        VStack(alignment: .leading) {
            TitleValueInlineView(title: "Time") {
                Text(
                    Date(timeIntervalSinceReferenceDate: stats.time),
                    format: Date.FormatStyle(date: .omitted, time: .standard, capitalizationContext: .middleOfSentence)
                )
            }
            
            TitleValueInlineView(title: "Distance") {
                Text(
                    Measurement(value: stats.distance, unit: UnitLength.meters),
                    format: .measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            TitleValueInlineView(title: "Altitude") {
                Text(
                    Measurement(value: stats.altitude, unit: UnitLength.meters),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .altitude))
            
            TitleValueInlineView(title: "Grade") {
                Text(
                    stats.grade,
                    format: .percent.precision(.fractionLength(2))
                )
            }
            
            TitleValueInlineView(title: "Speed") {
                Text(
                    Measurement(value: stats.speed, unit: UnitSpeed.metersPerSecond),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .speed))
            
            TitleValueInlineView(title: "Heart Rate") {
                Text(
                    Measurement(value: stats.heartRate, unit: UnitFrequency.hertz),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
            }
            .foregroundStyle(Color(uiColor: .heartRate))
        }
    }
}
