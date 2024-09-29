//
//  UnitPreferences.swift
//  WorkoutSpot
//
//  Created by Leptos on 9/29/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import Foundation
import os

final class UnitPreferences: ObservableObject {
    static let shared = UnitPreferences()
    
    private static let logger = Logger(subsystem: "null.leptos.WorkoutSpot", category: "UnitPreferences")
    
    private let userDefaults: UserDefaults = .standard
    
    @Published public var distanceUnit: UnitLength {
        didSet {
            updateUserDefaults(distanceUnit, for: distanceUnitKey)
        }
    }
    @Published public var altitudeUnit: UnitLength {
        didSet {
            updateUserDefaults(altitudeUnit, for: altitudeUnitKey)
        }
    }
    @Published public var speedUnit: UnitSpeed {
        didSet {
            updateUserDefaults(speedUnit, for: speedUnitKey)
        }
    }
    
    private let distanceUnitKey: String = "WSUnitPreferencesDistanceKey"
    private let altitudeUnitKey: String = "WSUnitPreferencesAltitudeKey"
    private let speedUnitKey: String = "WSUnitPreferencesSpeedKey"
    
    private static func readValue<Object>(for key: String, userDefaults: UserDefaults, defaultValue: () -> Object) -> Object where Object: NSObject, Object: NSSecureCoding {
        do {
            let value: Object? = try userDefaults.unarchivedObject(forKey: key)
            return value ?? defaultValue()
        } catch {
            logger.error("Failed to decode \(Object.self) for \(key): \(error as NSError)")
            return defaultValue()
        }
    }
    
    init() {
        let locale = Locale.current
        self.distanceUnit = Self.readValue(for: distanceUnitKey, userDefaults: userDefaults) {
            switch locale.measurementSystem {
            case .us: .miles
            default: .kilometers
            }
        }
        self.altitudeUnit = Self.readValue(for: altitudeUnitKey, userDefaults: userDefaults) {
            switch locale.measurementSystem {
            case .us: .feet
            default: .meters
            }
        }
        self.speedUnit = Self.readValue(for: speedUnitKey, userDefaults: userDefaults) {
            switch locale.measurementSystem {
            case .us: .milesPerHour
            default: .kilometersPerHour
            }
        }
    }
    
    private func updateUserDefaults<Object>(_ value: Object, for key: String) where Object: NSObject, Object: NSSecureCoding {
        let check: Object? = try? userDefaults.unarchivedObject(forKey: key)
        if value == check { return }
        Self.logger.debug("Writing \(String(describing: value)) for \(key)")
        
        do {
            try userDefaults.setArchived(object: value, forKey: key)
        } catch {
            Self.logger.error("Failed to encode \(Object.self) for \(key): \(error as NSError)")
        }
    }
}
