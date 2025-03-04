//
//  GatherScreenshots.swift
//  WorkoutSpotUITests
//
//  Created by Leptos on 10/6/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import XCTest

// copied from https://github.com/leptos-null/PrayerTimes/blob/640f1fb/PrayerTimesUITests/GatherScreenshots.swift

class GatherScreenshots: XCTestCase {
    private var directory: URL?
    private var paths: [String: String] = [:] // file name, description
    
    override func setUp() {
        continueAfterFailure = false
        
        let file = URL(fileURLWithPath: #file)
        let project = URL(fileURLWithPath: "..", isDirectory: true, relativeTo: file)
        
#if targetEnvironment(macCatalyst)
        let model = "macOS"
#else
        let environment = ProcessInfo.processInfo.environment
        guard let model = environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Screenshot collection should be run in the simulator")
        }
#endif
        
        let directory = project
            .appendingPathComponent("Screenshots")
            .appendingPathComponent(model)
        
        let fileManager: FileManager = .default
        
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            assert(isDirectory.boolValue, "\(directory.path) should be a directory")
        } else {
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        self.directory = directory
    }
    
    override func tearDown() {
        var readMe: String = ""
        
#if targetEnvironment(macCatalyst)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        readMe += "## macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)\n\n"
#else
        let environment = ProcessInfo.processInfo.environment
        guard let deviceName = environment["SIMULATOR_DEVICE_NAME"] else {
            fatalError("SIMULATOR_DEVICE_NAME is not set")
        }
        guard let version = environment["SIMULATOR_RUNTIME_VERSION"] else {
            fatalError("SIMULATOR_RUNTIME_VERSION is not set")
        }
        readMe += "## \(deviceName) \(version)\n\n"
#endif
        
        paths
            .sorted { lhs, rhs in
                lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
            }
            .forEach { pair in
                readMe += "![\(pair.value)](\(pair.key))\n\n"
            }
        
        guard let directory = directory else {
            fatalError("directory is unset")
        }
        
        let fileName = directory.appendingPathComponent("README.md")
        try! readMe.write(to: fileName, atomically: true, encoding: .ascii)
    }
    
    private func write(screenshot: XCUIScreenshot, name: String, description: String? = nil) {
        guard let directory = directory else {
            fatalError("directory is unset")
        }
        
        let path = directory.appendingPathComponent(name).appendingPathExtension("png")
        try! screenshot.pngRepresentation.write(to: path, options: .atomic)
        paths[path.lastPathComponent] = (description ?? name)
    }
    
    /*
     influenced by https://github.com/jessesquires/Nine41
     
     $ xcrun simctl list | grep Booted # find booted devices
     run the following for the device you'll be gathering screenshots on:
     
     xcrun simctl status_bar <device> override \
     --time "2023-09-12T16:41:30.000Z" \
     --dataNetwork "wifi" --wifiMode "active" --wifiBars 3 \
     --cellularMode active --cellularBars 4 --operatorName " " \
     --batteryState charged --batteryLevel 100
     */
    private func statusBarOverrideCommand() -> String {
        let environment = ProcessInfo.processInfo.environment
        guard let deviceUDID = environment["SIMULATOR_UDID"] else {
            fatalError("SIMULATOR_UDID is not set")
        }
        return
"""
xcrun simctl status_bar \(deviceUDID) override \
--time "2023-09-12T16:41:30.000Z" \
--dataNetwork "wifi" --wifiMode "active" --wifiBars 3 \
--cellularMode active --cellularBars 4 --operatorName " " \
--batteryState charged --batteryLevel 100
"""
    }
    
    func testGetScreenshots() {
        let app = XCUIApplication()
        
        app.launch()
        
        let window: XCUIElement = app.windows.firstMatch
        
        write(screenshot: window.screenshot(), name: "0_home", description: "Home")
        window.collectionViews.cells.staticTexts["10min 23sec"].tap() // AP2IL - Apple Park to Infinite Loop
        sleep(1) // wait for map content to fully show up
        
        let graphScrollView = window.scrollViews.firstMatch
        
        write(screenshot: window.screenshot(), name: "1_time", description: "Time, full route")
        
        graphScrollView.pinch(withScale: 2, velocity: 2)
        write(screenshot: window.screenshot(), name: "2_time_segment", description: "Time segment")
        
        graphScrollView.swipeLeft() // effectively pick a random spot
        write(screenshot: window.screenshot(), name: "3_time_point", description: "Time point")
        
        window.segmentedControls.buttons["Distance"].tap()
        graphScrollView.swipeRight() // effectively pick another spot
        write(screenshot: window.screenshot(), name: "4_distance_point", description: "Distance point")
        
        graphScrollView.tap() // hide point stats view
        write(screenshot: window.screenshot(), name: "5_distance_segment", description: "Distance segment")
    }
}
