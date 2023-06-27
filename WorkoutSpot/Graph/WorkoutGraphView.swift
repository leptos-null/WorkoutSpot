//
//  WorkoutGraphView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/26/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit
import SwiftUI

struct WorkoutGraphView: UIViewRepresentable {
    var keyedData: KeyedWorkoutData
    
    @Binding var selectedIndex: KeyedWorkoutData.Index?
    @Binding var selectedRange: KeyedWorkoutData.Indices
    
    func makeUIView(context: Context) -> GraphView {
        GraphView(keyedData: keyedData, selectedIndex: _selectedIndex, selectedRange: _selectedRange)
    }
    
    func updateUIView(_ view: GraphView, context: Context) {
        if view.keyedData !== keyedData {
            view.resetSources(keyedData: keyedData, selectedIndex: _selectedIndex, selectedRange: _selectedRange)
        }
    }
}

class GraphView: UIView {
    // this should only be written to from `init` or `resetSources`
    private(set) var keyedData: KeyedWorkoutData
    
    @Binding var selectedIndex: KeyedWorkoutData.Index? {
        didSet {
            updatePointMarks()
        }
    }
    
    @Binding var selectedRange: KeyedWorkoutData.Indices {
        didSet {
            drawView.data = keyedData[selectedRange]
        }
    }
    
    let scrollView = UIScrollView()
    let drawView = GraphDrawView()
    
    private let scrollViewContent = UIView()
    
    func resetSources(keyedData: KeyedWorkoutData, selectedIndex: Binding<KeyedWorkoutData.Index?>, selectedRange: Binding<KeyedWorkoutData.Indices>) {
        self.keyedData = keyedData
        
        // these do not trigger the `didSet` blocks
        self._selectedIndex = selectedIndex
        self._selectedRange = selectedRange
        
        updateForNewSources()
    }
    
    private func updateForNewSources() {
        drawView.data = keyedData[selectedRange]
        
        scrollView.maximumZoomScale = max(1, CGFloat(keyedData.count) / 24.0)
        
        updateScrollViewForSelectedRange()
        updatePointMarks()
    }
    
    init(keyedData: KeyedWorkoutData, selectedIndex: Binding<KeyedWorkoutData.Index?>, selectedRange: Binding<KeyedWorkoutData.Indices>) {
        self.keyedData = keyedData
        self._selectedIndex = selectedIndex
        self._selectedRange = selectedRange
        super.init(frame: .zero)
        
        scrollView.delegate = self
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        drawView.backgroundColor = .systemBackground
        drawView.graphInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        drawView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(scrollView)
        self.insertSubview(drawView, belowSubview: scrollView)
        
        scrollView.addSubview(scrollViewContent)
        
        scrollView.constrainEdges(equalTo: self)
        drawView.constrainEdges(equalTo: scrollView)
        
        NSLayoutConstraint.activate([
            scrollViewContent.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollViewContent.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor),
            scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollViewContent.rightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.rightAnchor),
            
            scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollViewContent.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        // disable other scroll inputs for this gesture so that the scroll view gets them
        panGesture.allowedScrollTypesMask = []
        
        scrollView.addGestureRecognizer(panGesture)
        
        let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(handleHoverGesture(_:)))
        scrollView.addGestureRecognizer(hoverGesture)
        
        updateForNewSources()
    }
    
    private func setSelectedIndexForX(_ x: CGFloat) {
        guard let guides = drawView.guides else { return }
        let floatingOffset = guides.keySeries.floatingOffsetForX(x)
        let floatingBase = CGFloat(selectedRange.lowerBound)
        
        selectedIndex = keyedData.bestClosedIndex(for: floatingBase + floatingOffset)
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            let touchPoint = gesture.location(in: drawView)
            setSelectedIndexForX(touchPoint.x)
        default:
            break
        }
    }
    
    @objc func handleHoverGesture(_ gesture: UIHoverGestureRecognizer) {
        guard gesture.modifierFlags.contains(.alternate) else { return }
        
        switch gesture.state {
        case .began, .changed:
            let hoverPoint = gesture.location(in: drawView)
            setSelectedIndexForX(hoverPoint.x)
        case .ended:
            selectedIndex = nil
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateRange() {
        let percentStart = scrollView.contentOffset.x / scrollView.contentSize.width
        let length = CGFloat(keyedData.count) / scrollView.zoomScale
        
        let startIndex = keyedData.indexForPercent(percentStart)
        let endIndex = keyedData.bestHalfOpenIndex(for: CGFloat(startIndex) + length)
        let range = startIndex..<endIndex
        
        if selectedRange != range {
            selectedRange = range
        }
    }
    
    private func updateScrollViewForSelectedRange() {
        let fullCount = keyedData.count
        
        scrollView.zoomScale = CGFloat(fullCount) / CGFloat(selectedRange.count)
        scrollView.contentOffset = CGPoint(
            x: scrollView.contentSize.width * CGFloat(selectedRange.lowerBound) / CGFloat(fullCount),
            y: 0
        )
    }
    
    private func updatePointMarks() {
        drawView.pointMarksIndex = selectedIndex
    }
}

extension GraphView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollViewContent
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateRange()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateRange()
    }
}
