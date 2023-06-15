//
//  WorkoutSpotApp.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/14/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI

@main
struct WorkoutSpotApp: App {
    let healthStore = HealthStore()
    
    var body: some Scene {
        WindowGroup {
            WorkoutList(healthStore: healthStore)
        }
    }
}
