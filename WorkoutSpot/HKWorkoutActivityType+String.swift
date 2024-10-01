//
//  HKWorkoutActivityType+String.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType: @retroactive CustomDebugStringConvertible {
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

extension HKWorkoutActivityType {
    var systemImageName: String? {
        switch self {
        case .americanFootball:
            "figure.american.football"
        case .archery:
            "figure.archery"
        case .australianFootball:
            "figure.australian.football"
        case .badminton:
            "figure.badminton"
        case .baseball:
            "figure.baseball"
        case .basketball:
            "figure.basketball"
        case .bowling:
            "figure.bowling"
        case .boxing:
            "figure.boxing"
        case .climbing:
            "figure.climbing"
        case .cricket:
            "figure.cricket"
        case .crossTraining:
            "figure.cross.training"
        case .curling:
            "figure.curling"
        case .cycling:
            "figure.outdoor.cycle" // figure.indoor.cycle
        case .dance:
            "figure.dance"
        case .danceInspiredTraining:
            "figure.dance" // duplicate because this is deprecated
        case .elliptical:
            "figure.elliptical"
        case .equestrianSports:
            "figure.equestrian.sports"
        case .fencing:
            "figure.fencing"
        case .fishing:
            "figure.fishing"
        case .functionalStrengthTraining:
            "figure.strengthtraining.functional"
        case .golf:
            "figure.golf"
        case .gymnastics:
            "figure.gymnastics"
        case .handball:
            "figure.handball"
        case .hiking:
            "figure.hiking"
        case .hockey:
            "figure.hockey"
        case .hunting:
            "figure.hunting"
        case .lacrosse:
            "figure.lacrosse"
        case .martialArts:
            "figure.martial.arts"
        case .mindAndBody:
            "figure.mind.and.body"
        case .mixedMetabolicCardioTraining:
            "figure.mixed.cardio"
        case .paddleSports:
            nil // "oar.2.crossed"
        case .play:
            "figure.play"
        case .preparationAndRecovery:
            "figure.rolling"
        case .racquetball:
            "figure.racquetball"
        case .rowing:
            "figure.rower"
        case .rugby:
            "figure.rugby"
        case .running:
            "figure.run"
        case .sailing:
            "figure.sailing"
        case .skatingSports:
            "figure.skating"
        case .snowSports:
            "snowflake" // general snow
        case .soccer:
            "figure.soccer"
        case .softball:
            "figure.softball"
        case .squash:
            "figure.squash"
        case .stairClimbing:
            "figure.stair.stepper"
        case .surfingSports:
            "figure.surfing"
        case .swimming:
            "figure.pool.swim" // figure.open.water.swim
        case .tableTennis:
            "figure.table.tennis"
        case .tennis:
            "figure.tennis"
        case .trackAndField:
            "figure.track.and.field"
        case .traditionalStrengthTraining:
            "figure.strengthtraining.traditional"
        case .volleyball:
            "figure.volleyball"
        case .walking:
            "figure.walk"
        case .waterFitness:
            "figure.water.fitness"
        case .waterPolo:
            "figure.waterpolo"
        case .waterSports:
            "water.waves" // general water
        case .wrestling:
            "figure.wrestling"
        case .yoga:
            "figure.yoga"
        case .barre:
            "figure.barre"
        case .coreTraining:
            "figure.core.training"
        case .crossCountrySkiing:
            "figure.skiing.crosscountry"
        case .downhillSkiing:
            "figure.skiing.downhill"
        case .flexibility:
            "figure.flexibility"
        case .highIntensityIntervalTraining:
            "figure.highintensity.intervaltraining"
        case .jumpRope:
            "figure.jumprope"
        case .kickboxing:
            "figure.kickboxing"
        case .pilates:
            "figure.pilates"
        case .snowboarding:
            "figure.snowboarding"
        case .stairs:
            "figure.stairs"
        case .stepTraining:
            "figure.step.training"
        case .wheelchairWalkPace:
            "figure.roll"
        case .wheelchairRunPace:
            "figure.roll.runningpace"
        case .taiChi:
            "figure.taichi"
        case .mixedCardio:
            "figure.mixed.cardio"
        case .handCycling:
            "figure.hand.cycling"
        case .discSports:
            "figure.disc.sports"
        case .fitnessGaming:
            nil
        case .cardioDance:
            "figure.dance" // note: double use of image
        case .socialDance:
            "figure.socialdance"
        case .pickleball:
            "figure.pickleball"
        case .cooldown:
            "figure.cooldown"
        case .swimBikeRun:
            nil
        case .transition:
            nil
        case .underwaterDiving:
            nil // "water.waves.and.arrow.down"
        case .other:
            nil
        @unknown default:
            nil
        }
    }
}

extension HKWorkoutActivityType {
    var localizedName: String {
        switch self {
        case .americanFootball: "American Football"
        case .archery: "Archery"
        case .australianFootball: "Australian Football"
        case .badminton: "Badminton"
        case .baseball: "Baseball"
        case .basketball: "Basketball"
        case .bowling: "Bowling"
        case .boxing: "Boxing"
        case .climbing: "Climbing"
        case .cricket: "Cricket"
        case .crossTraining: "Cross Training"
        case .curling: "Curling"
        case .cycling: "Cycling"
        case .dance: "Dance"
        case .danceInspiredTraining: "Dance Inspired Training"
        case .elliptical: "Elliptical"
        case .equestrianSports: "Equestrian Sports"
        case .fencing: "Fencing"
        case .fishing: "Fishing"
        case .functionalStrengthTraining: "Functional Strength Training"
        case .golf: "Golf"
        case .gymnastics: "Gymnastics"
        case .handball: "Handball"
        case .hiking: "Hiking"
        case .hockey: "Hockey"
        case .hunting: "Hunting"
        case .lacrosse: "Lacrosse"
        case .martialArts: "Martial Arts"
        case .mindAndBody: "Mind and Body"
        case .mixedMetabolicCardioTraining: "Mixed Metabolic Cardio Training"
        case .paddleSports: "Paddle Sports"
        case .play: "Play"
        case .preparationAndRecovery: "Preparation and Recovery"
        case .racquetball: "Racquetball"
        case .rowing: "Rowing"
        case .rugby: "Rugby"
        case .running: "Running"
        case .sailing: "Sailing"
        case .skatingSports: "Skating Sports"
        case .snowSports: "Snow Sports"
        case .soccer: "Soccer"
        case .softball: "Softball"
        case .squash: "Squash"
        case .stairClimbing: "Stair Climbing" // iOS sometimes calls this "Stair Stepper"
        case .surfingSports: "Surfing Sports"
        case .swimming: "Swimming"
        case .tableTennis: "Table Tennis"
        case .tennis: "Tennis"
        case .trackAndField: "Track and Field"
        case .traditionalStrengthTraining: "Traditional Strength Training"
        case .volleyball: "Volleyball"
        case .walking: "Walking"
        case .waterFitness: "Water Fitness"
        case .waterPolo: "Water Polo"
        case .waterSports: "Water Sports"
        case .wrestling: "Wrestling"
        case .yoga: "Yoga"
        case .barre: "Barre"
        case .coreTraining: "Core Training"
        case .crossCountrySkiing: "Cross Country Skiing"
        case .downhillSkiing: "Downhill Skiing"
        case .flexibility: "Flexibility"
        case .highIntensityIntervalTraining: "High Intensity Interval Training"
        case .jumpRope: "Jump Rope"
        case .kickboxing: "Kickboxing"
        case .pilates: "Pilates"
        case .snowboarding: "Snowboarding"
        case .stairs: "Stairs"
        case .stepTraining: "Step Training"
        case .wheelchairWalkPace: "Wheelchair Walk Pace"
        case .wheelchairRunPace: "Wheelchair Run Pace"
        case .taiChi: "Tai Chi"
        case .mixedCardio: "Mixed Cardio"
        case .handCycling: "Hand Cycling"
        case .discSports: "Disc Sports"
        case .fitnessGaming: "Fitness Gaming"
        case .cardioDance: "Cardio Dance" // iOS just calls this "Dance" - that might just be to ease the transition from the deprecated "dance" case
        case .socialDance: "Social Dance"
        case .pickleball: "Pickleball"
        case .cooldown: "Cooldown"
        case .swimBikeRun: "Multisport" // "Swim Bike Run"
        case .transition: "Transition" // iOS calls this "Activity Transition" - see docs: workouts themeselves shouldn't be of this type, instead activities within a workout can be of this type
        case .underwaterDiving: "Underwater Diving" // iOS just calls this "Dive"
        case .other: "Other"
        @unknown default: "Unknown"
        }
    }
}
