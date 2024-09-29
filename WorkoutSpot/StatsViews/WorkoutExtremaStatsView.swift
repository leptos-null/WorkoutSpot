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
    
    private func value(for series: Slice<ScalarSeries>) -> ScalarSeries.Element {
        switch extrema {
        case .min: series.minimum()
        case .max: series.maximum()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let altitude = data.altitude {
                Text(
                    Measurement(value: value(for: altitude), unit: UnitLength.meters),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
                .foregroundStyle(Color(uiColor: .altitude))
            }
            if let speed = data.speed {
                Text(
                    Measurement(value: value(for: speed), unit: UnitSpeed.metersPerSecond),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
                .foregroundStyle(Color(uiColor: .speed))
            }
            if let heartRate = data.heartRate {
                Text(
                    Measurement(value: value(for: heartRate), unit: UnitFrequency.hertz),
                    format: .measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(2)))
                )
                .foregroundStyle(Color(uiColor: .heartRate))
            }
        }
        .font(.footnote)
    }
}
