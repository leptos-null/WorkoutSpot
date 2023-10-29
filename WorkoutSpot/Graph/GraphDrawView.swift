//
//  GraphDrawView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/25/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit
import Combine

final class GraphDrawViewModel: ObservableObject {
    @Published fileprivate(set) var guides: GraphGuides<KeyedWorkoutData.SubSequence, ScalarSeries.SubSequence>?
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        self.guides = nil
        
        $guides
            .removeDuplicates(by: ===)
            .sink { [unowned self] _ in
                objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

@MainActor
class GraphDrawView: UIView {
    let viewModel: GraphDrawViewModel
    
    var data: KeyedWorkoutData.SubSequence? {
        didSet { updateGuides() }
    }
    
    var graphInsets: UIEdgeInsets = .zero {
        didSet { updateGuides() }
    }
    
    var pointMarksIndex: KeyedWorkoutData.Index? {
        didSet { setNeedsDisplay() }
    }
    
    init(viewModel: GraphDrawViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var bounds: CGRect {
        didSet { updateGuides() }
    }
    
    private func updateGuides() {
        let size = bounds.size
        guard let data, size.width > 0, !data.isEmpty else {
            viewModel.guides = nil
            return
        }
        let config = GraphConfig(dataCount: data.count, size: size, graphInsets: graphInsets)
        viewModel.guides = GraphGuides(data: data, config: config)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let guides = viewModel.guides else { return }
        
        let pairs: [(guide: GraphGuide, color: UIColor)] = [
            (guides.heartRate, .heartRate),
            (guides.speed, .speed),
            (guides.altitude, .altitude),
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
