//
//  WorkoutExtremaStatsView.swift
//  WorkoutSpot
//
//  Created by Leptos on 9/29/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import SwiftUI

struct WorkoutExtremaStatsView: View {
    enum ExtremaType {
        case min
        case max
    }
    
    let data: KeyedWorkoutData.SubSequence
    let extrema: ExtremaType
    
    @StateObject private var unitPreferences: UnitPreferences = .shared
    
    private func value(for series: Slice<ScalarSeries>) -> ScalarSeries.Element {
        switch extrema {
        case .min: series.minimum()
        case .max: series.maximum()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let altitude = data.altitude {
                Text.meters(value(for: altitude), width: .abbreviated, unit: unitPreferences.altitudeUnit)
                    .foregroundStyle(Color(uiColor: .altitude))
            }
            if let speed = data.speed {
                Text.metersPerSecond(value(for: speed), width: .abbreviated, unit: unitPreferences.speedUnit)
                    .foregroundStyle(Color(uiColor: .speed))
            }
            if let heartRate = data.heartRate {
                Text.beatsPerSecond(value(for: heartRate), width: .abbreviated)
                    .foregroundStyle(Color(uiColor: .heartRate))
            }
            if let runningPower = data.runningPower {
                Text(watts: value(for: runningPower), width: .abbreviated)
                    .foregroundStyle(Color(uiColor: .runningPower))
            }
        }
        .font(.footnote)
    }
}
