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
    
    @StateObject private var unitPreferences: UnitPreferences = .shared
    
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
                    Text.meters(distance, width: .abbreviated, unit: unitPreferences.distanceUnit)
                }
            }
            if let altitude = stats.altitude {
                TitleValueInlineView(title: "Altitude") {
                    Text.meters(altitude, width: .abbreviated, unit: unitPreferences.altitudeUnit)
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
                    Text.metersPerSecond(speed, width: .abbreviated, unit: unitPreferences.speedUnit)
                }
                .foregroundStyle(Color(uiColor: .speed))
            }
            if let heartRate = stats.heartRate {
                TitleValueInlineView(title: "♥ Rate", accessibilityLabel: "Heart Rate") {
                    Text.beatsPerSecond(heartRate, width: .abbreviated)
                }
                .foregroundStyle(Color(uiColor: .heartRate))
            }
            if let runningPower = stats.runningPower {
                TitleValueInlineView(title: "Power") {
                    Text(watts: runningPower, width: .abbreviated)
                }
                .foregroundStyle(Color(uiColor: .runningPower))
            }
        }
    }
}
