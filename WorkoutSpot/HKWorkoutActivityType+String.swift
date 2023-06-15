//
//  HKWorkoutActivityType+String.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .americanFootball:
            "americanFootball"
        case .archery:
            "archery"
        case .australianFootball:
            "australianFootball"
        case .badminton:
            "badminton"
        case .baseball:
            "baseball"
        case .basketball:
            "basketball"
        case .bowling:
            "bowling"
        case .boxing:
            "boxing"
        case .climbing:
            "climbing"
        case .cricket:
            "cricket"
        case .crossTraining:
            "crossTraining"
        case .curling:
            "curling"
        case .cycling:
            "cycling"
        case .dance:
            "dance"
        case .danceInspiredTraining:
            "danceInspiredTraining"
        case .elliptical:
            "elliptical"
        case .equestrianSports:
            "equestrianSports"
        case .fencing:
            "fencing"
        case .fishing:
            "fishing"
        case .functionalStrengthTraining:
            "functionalStrengthTraining"
        case .golf:
            "golf"
        case .gymnastics:
            "gymnastics"
        case .handball:
            "handball"
        case .hiking:
            "hiking"
        case .hockey:
            "hockey"
        case .hunting:
            "hunting"
        case .lacrosse:
            "lacrosse"
        case .martialArts:
            "martialArts"
        case .mindAndBody:
            "mindAndBody"
        case .mixedMetabolicCardioTraining:
            "mixedMetabolicCardioTraining"
        case .paddleSports:
            "paddleSports"
        case .play:
            "play"
        case .preparationAndRecovery:
            "preparationAndRecovery"
        case .racquetball:
            "racquetball"
        case .rowing:
            "rowing"
        case .rugby:
            "rugby"
        case .running:
            "running"
        case .sailing:
            "sailing"
        case .skatingSports:
            "skatingSports"
        case .snowSports:
            "snowSports"
        case .soccer:
            "soccer"
        case .softball:
            "softball"
        case .squash:
            "squash"
        case .stairClimbing:
            "stairClimbing"
        case .surfingSports:
            "surfingSports"
        case .swimming:
            "swimming"
        case .tableTennis:
            "tableTennis"
        case .tennis:
            "tennis"
        case .trackAndField:
            "trackAndField"
        case .traditionalStrengthTraining:
            "traditionalStrengthTraining"
        case .volleyball:
            "volleyball"
        case .walking:
            "walking"
        case .waterFitness:
            "waterFitness"
        case .waterPolo:
            "waterPolo"
        case .waterSports:
            "waterSports"
        case .wrestling:
            "wrestling"
        case .yoga:
            "yoga"
        case .barre:
            "barre"
        case .coreTraining:
            "coreTraining"
        case .crossCountrySkiing:
            "crossCountrySkiing"
        case .downhillSkiing:
            "downhillSkiing"
        case .flexibility:
            "flexibility"
        case .highIntensityIntervalTraining:
            "highIntensityIntervalTraining"
        case .jumpRope:
            "jumpRope"
        case .kickboxing:
            "kickboxing"
        case .pilates:
            "pilates"
        case .snowboarding:
            "snowboarding"
        case .stairs:
            "stairs"
        case .stepTraining:
            "stepTraining"
        case .wheelchairWalkPace:
            "wheelchairWalkPace"
        case .wheelchairRunPace:
            "wheelchairRunPace"
        case .taiChi:
            "taiChi"
        case .mixedCardio:
            "mixedCardio"
        case .handCycling:
            "handCycling"
        case .discSports:
            "discSports"
        case .fitnessGaming:
            "fitnessGaming"
        case .cardioDance:
            "cardioDance"
        case .socialDance:
            "socialDance"
        case .pickleball:
            "pickleball"
        case .cooldown:
            "cooldown"
        case .swimBikeRun:
            "swimBikeRun"
        case .transition:
            "transition"
        case .underwaterDiving:
            "underwaterDiving"
        case .other:
            "other"
        @unknown default:
            "@unknown (\(rawValue))"
        }
    }
}
