//
//  Text+Measurement.swift
//  WorkoutSpot
//
//  Created by Leptos on 9/29/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import SwiftUI

// these automatically have good accessibility labels.
// i.e. the Text shows "2 mi" on screen, but reads "2 miles"
extension Text {
    init(meters: Double, width: Measurement<UnitLength>.FormatStyle.UnitWidth, unit: UnitLength) {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        self.init(
            measurement.converted(to: unit),
            format: .measurement(width: width, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(2)))
        )
    }
    
    init(metersPerSecond: Double, width: Measurement<UnitSpeed>.FormatStyle.UnitWidth, unit: UnitSpeed) {
        let measurement = Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
        self.init(
            measurement.converted(to: unit),
            format: .measurement(width: width, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(2)))
        )
    }
}

extension Text {
    private init(beatsPerSecond: Double, width: Measurement<UnitFrequency>.FormatStyle.UnitWidth) {
        let beatsPerMinute = beatsPerSecond * 60
        let formatted = beatsPerMinute.formatted(.number.precision(.fractionLength(0)))
        
        let string: String
        switch width {
        case .wide: string = formatted + " beats per minute"
        case .abbreviated: string = formatted + " BPM"
        case .narrow: string = formatted + "bpm"
        default:
            assertionFailure("Unknown unit width: \(width)")
            string = formatted
        }
        self.init(verbatim: string)
    }
    
    static func beatsPerSecond(_ beatsPerSecond: Double, width: Measurement<UnitFrequency>.FormatStyle.UnitWidth) -> Text {
        Text(beatsPerSecond: beatsPerSecond, width: width)
            .accessibilityLabel(Text(beatsPerSecond: beatsPerSecond, width: .wide))
    }
}
