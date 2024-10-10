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
    
    var showGridLines: Bool = false {
        didSet { setNeedsDisplay() }
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
        
        let pairs: [(guide: GraphGuide?, color: UIColor)] = [
            (guides.cyclingPower, .cyclingPower),
            (guides.runningPower, .runningPower),
            (guides.heartRate, .heartRate),
            (guides.speed, .speed),
            (guides.altitude, .altitude),
        ]
        
        let validPairs: [(guide: GraphGuide, color: UIColor)] = pairs.compactMap { guide, color in
            guard let guide else { return nil }
            return (guide, color)
        }
        
        let indexOffset = guides.data.startIndex
        
        if showGridLines {
            UIColor.secondaryLabel.withAlphaComponent(0.3).setStroke()
            
            let graphConfig = guides.config
            
            // add a vertical line on the trailing edge of the graph.
            // this is just to add a "border" look
            let trailX = graphConfig.size.width - graphConfig.graphInsets.right
            let trailPath = UIBezierPath()
            trailPath.move(to: CGPoint(x: trailX, y: 0.5))
            trailPath.addLine(to: CGPoint(x: trailX, y: graphConfig.size.height - graphConfig.graphInsets.bottom))
            trailPath.stroke()
            
            // add 3 horizontal lines across the graph.
            // the first line is at the very top, which is just to add a "border" look
            let totalHeight = graphConfig.size.height
            for lineMarkY in stride(from: 0, to: totalHeight - graphConfig.graphInsets.bottom, by: totalHeight / 3) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: graphConfig.graphInsets.left, y: lineMarkY))
                path.addLine(to: CGPoint(x: graphConfig.size.width - graphConfig.graphInsets.right, y: lineMarkY))
                
                path.stroke()
            }
            
            if let keySeries = guides.keySeries {
                // our goal is to show vertical lines to visually segment the graph.
                // we would like the vertical lines to not move with respect to the underlying data.
                // i.e. if there's a vertical line at `time = 250 seconds` that line should
                // always be at `time = 250 seconds`, no matter how the user moves the graph
                // (unless the user zooms out and doesn't need to see so many lines).
                //
                // in order for the lines to not "move" as the user changes the selection range
                // we must divide the total range into `c * x**n` segments.
                //   `c` must be constant; minimum number of lines visible at once.
                //   `x` must be constant; how many segments a single segment is split into when the user zooms in.
                //   `n` a variable that is selected to satisfy:
                //     `c >= selection.count / (total.count / x**n )`
                //
                // this results in lines that do not "move" because `n + 1` multiplies
                // the result of `n` by `x`. So all the lines from `n` are present and
                // have not moved. lines are only added in-between the existing lines.
                // you can observe this with a function such as
                //
                //   func segment(t: Double, c: Double, x: Double, n: Double) -> [Double] {
                //       let width = t / (c * pow(x, n))
                //       return Array(stride(from: .zero, to: t, by: width))
                //   }
                //
                //   `t` is the total range count.
                //   select constant values for `t`, `c`, and `x`.
                //   vary `n` and observe that every value in the output for `n` is present in `n + 1`
                //
                // for selecting `n`, we simply solve the constraint for `n`:
                //   c <= selection.count / (total.count / x**n )
                //   c * (total.count / x**n ) <= selection.count
                //   c * total.count / x**n <= selection.count
                //   c * total.count <= selection.count * x**n
                //   c * total.count / selection.count <= x**n
                //   log_x(c * total.count / selection.count) <= n
                //
                // and minimize `n` so we show the least amount of lines
                // (otherwise the graph could be over-whelmed with lines).
                //
                // using this equation, I've selected `c = 2`, `x = 2`
                
                let baseCount = guides.data.base.count // `total.count` in notation above
                let selection = guides.data.indices // `selection` in notation above
                let scale = baseCount / selection.count
                let highestSetBitIndex = scale.bitWidth - scale.leadingZeroBitCount // logb(scale) + 1
                // slide another 1 bit to multiply by another 2
                let segmentCount = (1 << highestSetBitIndex) << 1
                
                let segmentSize = baseCount / segmentCount
                let selectionMod = selection.lowerBound % segmentSize
                let firstLine = (selectionMod == 0) ? selection.lowerBound : (selection.lowerBound - selectionMod + segmentSize)
                let lines = stride(from: firstLine, to: selection.upperBound, by: segmentSize)
                
                let validX = graphConfig.graphInsets.left...(graphConfig.size.width - graphConfig.graphInsets.right)
                for line in lines {
                    let pointX = keySeries.xForOffset(line - indexOffset)
                    guard validX ~= pointX else { continue }
                    
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: pointX, y: 0))
                    path.addLine(to: CGPoint(x: pointX, y: graphConfig.size.height - graphConfig.graphInsets.bottom))
                    
                    // start in the off phase so that the first dot doesn't
                    // intersect the top horizontal line
                    path.setLineDash([ 1, 2 ], count: 2, phase: 1)
                    path.stroke()
                }
            }
        }
        
        for (guide, color) in validPairs {
            color.setStroke()
            guide.path.stroke()
        }
        
        if let pointMarksIndex, let keyGuide = guides.keySeries {
            let pointMarkX = keyGuide.xForOffset(pointMarksIndex - indexOffset)
            
            for (guide, color) in validPairs {
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
