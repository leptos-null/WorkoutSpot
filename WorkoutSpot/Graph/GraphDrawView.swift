//
//  GraphDrawView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/25/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit

@MainActor
class GraphDrawView: UIView {
    var data: KeyedWorkoutData.SubSequence? {
        didSet { updateGuides() }
    }
    
    var graphInsets: UIEdgeInsets = .zero {
        didSet { updateGuides() }
    }
    
    var pointMarksIndex: KeyedWorkoutData.Index? {
        didSet { setNeedsDisplay() }
    }
    
    override var bounds: CGRect {
        didSet { updateGuides() }
    }
    
    private(set) var guides: GraphGuides<KeyedWorkoutData.SubSequence, ScalarSeries.SubSequence>?
    
    private func updateGuides() {
        let size = bounds.size
        guard let data, size.width > 0, !data.isEmpty else {
            guides = nil
            return
        }
        let config = GraphConfig(dataCount: data.count, size: size, graphInsets: graphInsets)
        guides = GraphGuides(data: data, config: config)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let guides else { return }
        
        let pairs = [
            (guides.heartRate, UIColor.systemRed),
            (guides.speed, UIColor.systemBlue),
            (guides.altitude, UIColor.systemOrange),
        ]
        
        for (guide, color) in pairs {
            color.setStroke()
            guide.path.stroke()
        }
        
        if let pointMarksIndex {
            let pointMarkX = guides.keySeries.xForOffset(pointMarksIndex - guides.data.startIndex)
            
            for (guide, color) in pairs {
                let pointMark = CGPoint(
                    x: pointMarkX,
                    y: guide.yForX(pointMarkX)
                )
                
                let markPath = UIBezierPath(circleCentered: pointMark, radius: 6)
                color.setFill()
                markPath.fill()
            }
        }
    }
}

extension UIBezierPath {
    convenience init(circleCentered center: CGPoint, radius: CGFloat) {
        let diameter = radius * 2
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: diameter,
            height: diameter
        )
        self.init(ovalIn: rect)
    }
}
