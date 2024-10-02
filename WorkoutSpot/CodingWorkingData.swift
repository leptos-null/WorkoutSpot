//
//  CodingWorkingData.swift
//  WorkoutSpot
//
//  Created by Leptos on 10/1/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import Foundation
import CoreLocation
import HealthKit

final class CodingWorkingData: NSObject, NSSecureCoding {
    private enum CodingKey {
        // it's not particularly important to have backward compatibilty here,
        // but these keys do match the original version
        static let workout = "WSWorkoutDataWorkoutKey"
        static let locations = "WSWorkoutDataLocationsKey"
        static let heartRates = "WSWorkoutDataHeartRatesKey"
        static let runningPower = "WSWorkoutDataRunningPowerKey"
        static let cyclingPower = "WSWorkoutDataCyclingPowerKey"
    }
    
    static var supportsSecureCoding: Bool { true }
    
    let underlying: RawWorkoutData
    
    init(_ underlying: RawWorkoutData) {
        self.underlying = underlying
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(underlying.workout as NSSecureCoding, forKey: CodingKey.workout)
        coder.encode(underlying.locations as NSSecureCoding, forKey: CodingKey.locations)
        coder.encode(underlying.heartRates as NSSecureCoding, forKey: CodingKey.heartRates)
        coder.encode(underlying.runningPower as NSSecureCoding, forKey: CodingKey.runningPower)
        coder.encode(underlying.cyclingPower as NSSecureCoding, forKey: CodingKey.cyclingPower)
    }
    
    convenience init?(coder: NSCoder) {
        guard let workout = coder.decodeObject(of: HKWorkout.self, forKey: CodingKey.workout) else { return nil }
        
        let locations = coder.decodeArrayOfObjects(ofClass: CLLocation.self, forKey: CodingKey.locations)
        let heartRates = coder.decodeArrayOfObjects(ofClass: HKDiscreteQuantitySample.self, forKey: CodingKey.heartRates)
        let runningPower = coder.decodeArrayOfObjects(ofClass: HKDiscreteQuantitySample.self, forKey: CodingKey.runningPower)
        let cyclingPower = coder.decodeArrayOfObjects(ofClass: HKDiscreteQuantitySample.self, forKey: CodingKey.cyclingPower)
        
        let underlying = RawWorkoutData(
            workout: workout,
            locations: locations ?? [],
            heartRates: heartRates ?? [],
            runningPower: runningPower ?? [],
            cyclingPower: cyclingPower ?? []
        )
        self.init(underlying)
    }
}

extension RawWorkoutData {
    func archived() throws -> Data {
        let wrapped = CodingWorkingData(self)
        return try NSKeyedArchiver.archivedData(withRootObject: wrapped, requiringSecureCoding: true)
    }
    
    class func unarchive(from data: Data) throws -> RawWorkoutData {
        let wrapped = try NSKeyedUnarchiver.unarchivedObject(ofClass: CodingWorkingData.self, from: data)
        guard let wrapped else {
            throw CocoaError(.coderValueNotFound)
        }
        return wrapped.underlying
    }
}
