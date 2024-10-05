//
//  AssetsContents.swift
//  WSIcon
//
//  Created by Leptos on 10/3/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import Foundation

// copied from https://github.com/leptos-null/PrayerTimes/blob/640f1fb/PrayerTimesIcon/ViewController.swift#L180

struct AppIconSetContents: Codable {
    struct Image: Codable {
        let platform: String?
        let idiom: String?
        let role: String?
        let scale: String?
        let size: String
        let subtype: String?
        var filename: String?
    }
    struct Info: Codable {
        var author: String
        var version: Int
    }
    var images: [Image]
    var info: Info
}

struct SolidImageStackContents: Codable {
    struct Layer: Codable {
        var filename: String?
    }
    struct Info: Codable {
        var author: String
        var version: Int
    }
    var layers: [Layer]
    var info: Info
}

struct ImageSetContents: Codable {
    struct Image: Codable {
        let platform: String?
        let idiom: String?
        let role: String?
        let scale: String?
        let size: String?
        let subtype: String?
        var filename: String?
    }
    struct Info: Codable {
        var author: String
        var version: Int
    }
    var images: [Image]
    var info: Info
}
