//
//  Text+Measurement.swift
//  WorkoutSpot
//
//  Created by Leptos on 9/29/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import SwiftUI

// We would like to use the `Text(_:format:)` API because it seems to be better practice,
// and the Text view automatically provides a better accessibility label than a plain string
// (e.g. the Text renders "2 mi" on screen, but has an accessibility label of "2 miles").
//
// During testing on iOS 17.6.1, I observed that the Text object described above
// would not re-draw if the old and new Measurement values are equal.
// This is problematic in this usage because `Measurement` equality does not
// take into consideration the unit of the Measurement
// (e.g. `m.converted(to: .meters) == m.converted(to: .astronomicalUnits)`).

extension Text {
    private init(meters: Double, width: Measurement<UnitLength>.FormatStyle.UnitWidth, unit: UnitLength) {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatted = measurement
            .converted(to: unit)
            .formatted(.measurement(
                width: width, usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            ))
        self.init(verbatim: formatted)
    }
    
    static func meters(_ meters: Double, width: Measurement<UnitLength>.FormatStyle.UnitWidth, unit: UnitLength) -> Text {
        Text(meters: meters, width: width, unit: unit)
            .accessibilityLabel(Text(meters: meters, width: .wide, unit: unit))
    }
}

extension Text {
    private init(metersPerSecond: Double, width: Measurement<UnitSpeed>.FormatStyle.UnitWidth, unit: UnitSpeed) {
        let measurement = Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
        let formatted = measurement
            .converted(to: unit)
            .formatted(.measurement(
                width: width, usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            ))
        self.init(verbatim: formatted)
    }
    
    static func metersPerSecond(_ metersPerSecond: Double, width: Measurement<UnitSpeed>.FormatStyle.UnitWidth, unit: UnitSpeed) -> Text {
        Text(metersPerSecond: metersPerSecond, width: width, unit: unit)
            .accessibilityLabel(Text(metersPerSecond: metersPerSecond, width: .wide, unit: unit))
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
