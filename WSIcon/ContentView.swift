//
//  ContentView.swift
//  WSIcon
//
//  Created by Leptos on 10/3/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import SwiftUI

// copied from https://github.com/leptos-null/PrayerTimes/blob/640f1fb/PrayerTimesIcon/ViewController.swift#L12

extension CGPoint {
    init(center: CGPoint, radius: CGFloat, angle: Double) {
        self.init(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

struct AppIcon {
    // the background color for the whole image before the "face" is drawn
    var backgroundFillColor: UIColor? = .black
    // currently, the color of the elements inside of the face
    var foregroundColor: UIColor = .white
    
    // padding between the closest edge of the "background fill" and the "face"
    // a value of 0 means no padding
    // a value of 0.5 means half of the size is padding
    var insetScaleFactor: CGFloat = 1/8.0
    
    // the ratio of the "background fill" size to the requested size
    var backgroundFillScaleFactor: CGFloat = 1
    // the corner radius of the "background fill"
    // a value of 0 means no corner radius
    // a value of 0.5 means a near circle
    var backgroundFillRadiusFactor: CGFloat = 0
    
    private func fillSize(for size: CGSize) -> CGSize {
        CGSize(
            width: size.width * backgroundFillScaleFactor,
            height: size.height * backgroundFillScaleFactor
        )
    }
    
    private func dimension(for size: CGSize) -> CGFloat {
        min(size.width, size.height)
    }
    
    func drawBackground(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        
        if let backgroundFillColor = backgroundFillColor {
            backgroundFillColor.setFill()
            
            let fillOrigin = CGPoint(
                x: (size.width - fillSize.width)/2,
                y: (size.height - fillSize.height)/2
            )
            UIBezierPath(
                roundedRect: CGRect(origin: fillOrigin, size: fillSize),
                cornerRadius: fillDimension * backgroundFillRadiusFactor
            ).fill()
        }
    }
    
    func drawFace(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        let dimension = fillDimension * (1 - insetScaleFactor)
        
        let facePath = UIBezierPath(ovalIn: CGRect(
            x: (size.width - dimension)/2, y: (size.height - dimension)/2,
            width: dimension, height: dimension
        ))
        
        let strokeWidth = dimension/48
        facePath.lineWidth = strokeWidth
        
        foregroundColor.setStroke()
        facePath.stroke()
        
        let hand = UIBezierPath()
        let handAngle = Double.pi * 1.825 // radians
        hand.lineWidth = strokeWidth
        hand.lineCapStyle = .round
        
        let handCenter = CGPoint(x: size.width/2, y: size.height/2 + dimension * 0.16)
        hand.move(to: handCenter)
        hand.addLine(to: CGPoint(center: handCenter, radius: dimension * 0.42, angle: handAngle))
        hand.stroke()
        
        let handPin = UIBezierPath()
        let handPinRadius = dimension/15
        let handPinSpacing = dimension/90
        let openingAngle = (strokeWidth + handPinSpacing * 2) / handPinRadius
        
        handPin.addArc(
            withCenter: handCenter, radius: handPinRadius,
            startAngle: (handAngle + openingAngle/2),
            endAngle: (handAngle - openingAngle/2),
            clockwise: true
        )
        handPin.addArc(
            withCenter: handCenter,
            radius: (strokeWidth/2 + handPinSpacing),
            startAngle: (handAngle - .pi/2),
            endAngle: (handAngle - .pi * 1.5),
            clockwise: false
        )
        
        foregroundColor.setFill()
        handPin.fill()
    }
    
    func drawForeground(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        let dimension = fillDimension * (1 - insetScaleFactor)
        
        foregroundColor.setFill()
        foregroundColor.setStroke()
        
        let strokeWidth = dimension/48
        
        let mountain = UIBezierPath()
        mountain.lineWidth = strokeWidth
        let mountainScale = dimension * 0.21
        let mountainStart = CGPoint(x: size.width/2 - dimension * 0.38, y: size.height/2 + dimension * 0.06)
        mountain.move(to: mountainStart)
        mountain.addLine(to: CGPoint(center: mountain.currentPoint, radius: mountainScale * 0.50, angle: .pi/3 * 5))
        mountain.addLine(to: CGPoint(center: mountain.currentPoint, radius: mountainScale * 0.17, angle: .pi/5 * 1))
        mountain.addLine(to: CGPoint(center: mountain.currentPoint, radius: mountainScale * 0.55, angle: .pi/3 * 5))
        // calculate the radius such that the y component is equal to the y component of mountainStart
        let mountainPeak = mountain.currentPoint
        let descentAngle = Double.pi/3
        mountain.addLine(to: CGPoint(center: mountainPeak, radius: (mountainStart.y - mountainPeak.y) / sin(descentAngle), angle: descentAngle))
        mountain.close()
        mountain.fill()
        
        let glyphSize = mountain.bounds.size
        
        let heart = UIBezierPath()
        heart.lineWidth = strokeWidth
        let heartRadius = glyphSize.height/sqrt(8)
        let heartTop = CGPoint(x: size.width/2 + dimension * 0.16, y: size.height/2 - dimension * 0.26)
        heart.addArc(
            withCenter: CGPoint(center: heartTop, radius: heartRadius, angle: .pi/4 * 3),
            radius: heartRadius,
            startAngle: (.pi/4 * 3), endAngle: (.pi/4 * 7),
            clockwise: true
        )
        heart.addArc(
            withCenter: CGPoint(center: heartTop, radius: heartRadius, angle: .pi/4 * 1),
            radius: heartRadius,
            startAngle: (.pi/4 * 5), endAngle: (.pi/4 * 9),
            clockwise: true
        )
        heart.addLine(to: CGPoint(x: heartTop.x, y: heartTop.y + heartRadius * sqrt(8)))
        heart.fill()
        
        let fontWeight = UIFont.Weight(strokeWidth)
        let imageConfig = UIImage.SymbolConfiguration(weight:fontWeight.symbolWeight())
        guard let locationImage = UIImage(systemName: "location.fill", withConfiguration: imageConfig) else {
            fatalError("Failed to create symbol for location.fill")
        }
        let coloredLocationImage = locationImage.withTintColor(foregroundColor)
        let locationRect = CGRect(
            x: size.width / 2 - dimension * 0.24, y: size.height / 2 - dimension * 0.35,
            width: glyphSize.width, height: glyphSize.width
        )
        coloredLocationImage.draw(in: locationRect)
    }
    
    func draw(size: CGSize) {
        drawBackground(size: size)
        drawFace(size: size)
        drawForeground(size: size)
    }
    
    func image(size: CGSize, opaque: Bool = false, scale: CGFloat? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        if let scale = scale {
            format.scale = scale
        }
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                draw(size: size)
            }
    }
    
    func pngData(size: CGSize, opaque: Bool = false, scale: CGFloat? = nil) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        if let scale = scale {
            format.scale = scale
        }
        return UIGraphicsImageRenderer(size: size, format: format)
            .pngData { context in
                draw(size: size)
            }
    }
    
    func pdfData(size: CGSize) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
            .pdfData { context in
                context.beginPage()
                draw(size: size)
            }
    }
}

// copied from https://github.com/leptos-null/PrayerTimes/blob/640f1fb4993f248f08be6a677fc152c08f2252cc/PrayerTimesIcon/ViewController.swift#L232
extension AppIconSetContents {
    static func writeIconAssets(for iconSet: URL, appIcon: AppIcon = AppIcon()) throws {
        let manifest = iconSet.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        var iconSetContents = try jsonDecoder.decode(Self.self, from: parse)
        
        iconSetContents.images = try iconSetContents.images.map { image in
            let scaleSuffix = image.scale ?? "1x"
            
            var imageScale = scaleSuffix
            guard imageScale.popLast() == Character("x") else { fatalError("scale must end with 'x' character") }
            guard let scale = Double(imageScale) else { fatalError("scale.dropLast() must be numeric") }
            
            let dimensions = image.size.split(separator: "x")
            guard dimensions.count == 2,
                  let width = Double(dimensions[0]),
                  let height = Double(dimensions[1]) else { fatalError("failed parsing dimensions") }
            let size = CGSize(width: width, height: height)
            
            let filenamePrefix: String
            if let platform = image.platform, let idiom = image.idiom {
                filenamePrefix = "\(platform)-\(idiom)"
            } else if let platform = image.platform {
                filenamePrefix = platform
            } else if let idiom = image.idiom {
                filenamePrefix = idiom
            } else {
                filenamePrefix = "icon"
            }
            
            let filename = "\(filenamePrefix)\(image.size)@\(scaleSuffix).png"
            
            let iconData: Data
            if image.idiom == "mac" {
                var macIcon = appIcon
                macIcon.insetScaleFactor = 0.136
                macIcon.backgroundFillScaleFactor = 0.806
                macIcon.backgroundFillRadiusFactor = 0.185
                
                iconData = macIcon.pngData(size: size, opaque: false, scale: scale)
            } else {
                iconData = appIcon.pngData(size: size, opaque: true, scale: scale)
            }
            
            try iconData.write(to: iconSet.appendingPathComponent(filename))
            
            var imgCopy = image
            imgCopy.filename = filename
            return imgCopy
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        let serialized = try jsonEncoder.encode(iconSetContents)
        try serialized.write(to: manifest)
    }
}

extension ImageSetContents {
    static func writeImage(for imageSet: URL, drawBlock: (CGSize) -> Void) throws {
        let manifest = imageSet.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        var imageSetContents = try jsonDecoder.decode(Self.self, from: parse)
        
        imageSetContents.images = try imageSetContents.images.map { image in
            let size: CGSize
            let scale: CGFloat
            let opaque: Bool
            
            guard image.idiom == "vision" else {
                fatalError("Currently this function only supports visionOS app icon image stacks")
            }
            // Xcode requests 512 @ 2x, but for some reason this breaks the ImageStack preview -
            // 1024 @ 1x seems to work fine though, so use this
            size = CGSize(width: 1024, height: 1024)
            scale = 1
            opaque = false
            
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            
            let iconData = UIGraphicsImageRenderer(size: size, format: format)
                .pngData { context in
                    drawBlock(size)
                }
            
            let filename = "icon.png"
            
            try iconData.write(to: imageSet.appendingPathComponent(filename))
            
            var imgCopy = image
            imgCopy.filename = filename
            return imgCopy
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        let serialized = try jsonEncoder.encode(imageSetContents)
        try serialized.write(to: manifest)
    }
}

extension SolidImageStackContents {
    static func writeSolidImageStack(for imageStack: URL, appIcon: AppIcon = AppIcon()) throws {
        let manifest = imageStack.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        let imageStackContents = try jsonDecoder.decode(Self.self, from: parse)
        
        let layerImageSets = imageStackContents.layers.map { layer in
            guard let filename = layer.filename else {
                fatalError("Layer must have a filename")
            }
            return imageStack
                .appendingPathComponent(filename)
                .appendingPathComponent("Content.imageset")
        }
        
        switch layerImageSets.count {
        case 1:
            try ImageSetContents.writeImage(for: layerImageSets[0]) { size in
                appIcon.draw(size: size)
            }
        case 2:
            try ImageSetContents.writeImage(for: layerImageSets[1]) { size in
                appIcon.drawBackground(size: size)
                appIcon.drawFace(size: size)
            }
            try ImageSetContents.writeImage(for: layerImageSets[0]) { size in
                appIcon.drawForeground(size: size)
            }
        case 3:
            try ImageSetContents.writeImage(for: layerImageSets[2]) { size in
                appIcon.drawBackground(size: size)
            }
            try ImageSetContents.writeImage(for: layerImageSets[1]) { size in
                appIcon.drawFace(size: size)
            }
            try ImageSetContents.writeImage(for: layerImageSets[0]) { size in
                appIcon.drawForeground(size: size)
            }
        default:
            fatalError("Image stack currently only supports 1, 2, or 3 layers")
        }
    }
}

enum WorkoutSpot {
    static func writeAllIcons() throws {
        let file = URL(fileURLWithPath: #file)
        let project = URL(fileURLWithPath: "..", isDirectory: true, relativeTo: file)
        
        let mobileIconSet = URL(fileURLWithPath: "WorkoutSpot/Assets.xcassets/AppIcon.appiconset", isDirectory: true, relativeTo: project)
        try AppIconSetContents.writeIconAssets(for: mobileIconSet)
        
        let visionImageStack = URL(fileURLWithPath: "WorkoutSpot/Assets.xcassets/AppIcon.solidimagestack", relativeTo: project)
        try SolidImageStackContents.writeSolidImageStack(for: visionImageStack, appIcon: AppIcon(insetScaleFactor: 1/5.0))
    }
}

struct ContentView: View {
    private let appIcon = AppIcon()
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Image(uiImage: appIcon.image(size: geometry.size))
            }
        }
        .scenePadding()
        .onAppear {
            try! WorkoutSpot.writeAllIcons()
        }
    }
}

#Preview {
    ContentView()
}
