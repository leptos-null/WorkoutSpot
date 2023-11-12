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
            if let time = stats.time {
                TitleValueInlineView(title: "Time") {
                    Text(
                        Date(timeIntervalSinceReferenceDate: time),
                        format: Date.FormatStyle(date: .omitted, time: .standard, capitalizationContext: .middleOfSentence)
                    )
                }
            }
            
            if let distance = stats.distance {
                TitleValueInlineView(title: "Distance") {
                    Text(
                        Measurement(value: distance, unit: UnitLength.meters),
                        format: .measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
            }
            if let altitude = stats.altitude {
                TitleValueInlineView(title: "Altitude") {
                    Text(
                        Measurement(value: altitude, unit: UnitLength.meters),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .altitude))
            }
            if let grade = stats.grade {
                TitleValueInlineView(title: "Grade") {
                    Text(
                        grade,
                        format: .percent.precision(.fractionLength(2))
                    )
                }
            }
            
            if let speed = stats.speed {
                TitleValueInlineView(title: "Speed") {
                    Text(
                        Measurement(value: speed, unit: UnitSpeed.metersPerSecond),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .speed))
            }
            if let heartRate = stats.heartRate {
                TitleValueInlineView(title: "Heart Rate") {
                    Text(
                        Measurement(value: heartRate, unit: UnitFrequency.hertz),
                        format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                    )
                }
                .foregroundStyle(Color(uiColor: .heartRate))
            }
        }
    }
}
