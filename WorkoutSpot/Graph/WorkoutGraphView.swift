//
//  WorkoutGraphView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/26/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

struct WorkoutGraphView: UIViewRepresentable {
    let keyedWorkoutViewModel: KeyedWorkoutViewModel
    let graphDrawViewModel: GraphDrawViewModel
    
    func makeUIView(context: Context) -> GraphView {
        GraphView(workoutViewModel: keyedWorkoutViewModel, drawViewModel: graphDrawViewModel)
    }
    
    func updateUIView(_ view: GraphView, context: Context) {
        if view.workoutViewModel !== keyedWorkoutViewModel {
            view.workoutViewModel = keyedWorkoutViewModel
        }
    }
}

class GraphView: UIView {
    let scrollView = UIScrollView()
    let drawView: GraphDrawView
    
    private let scrollViewContent = UIView()
    
    var workoutViewModel: KeyedWorkoutViewModel {
        didSet {
            subscribeToViewModel()
        }
    }
    
    let drawViewModel: GraphDrawViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
    private func subscribeToViewModel() {
        // cancel all immediately to avoid any changes that occur on initial
        // subscription in the new pipelines from affecting the old view model
        cancellables.removeAll(keepingCapacity: true)
        
        workoutViewModel.$synced
            .removeDuplicates { lhs, rhs in
                // we don't want to get changes for `selectionRange` too because that
                // results in a feedback loop with `updateScrollViewForSelectedRange`
                lhs.keyedData === rhs.keyedData
            }
            .sink { [unowned self] synced in
                let keyedData = synced.keyedData
                scrollView.maximumZoomScale = max(1, CGFloat(keyedData.count) / 24.0)
                updateScrollViewForSelectedRange(keyedData: keyedData, selectedRange: synced.selectionRange)
            }
            .store(in: &cancellables)
        
        workoutViewModel.$synced
            .removeDuplicates { lhs, rhs in
                (lhs.keyedData === rhs.keyedData) && (lhs.selectionRange == rhs.selectionRange)
            }
            .sink { [unowned self] synced in
                drawView.data = synced.keyedData[synced.selectionRange]
            }
            .store(in: &cancellables)
        
        workoutViewModel.$synced
            .map(\.selectionPoint)
            .removeDuplicates()
            .sink { [unowned self] selectionPoint in
                drawView.pointMarksIndex = selectionPoint
            }
            .store(in: &cancellables)
    }
    
    init(workoutViewModel: KeyedWorkoutViewModel, drawViewModel: GraphDrawViewModel) {
        self.workoutViewModel = workoutViewModel
        self.drawViewModel = drawViewModel
        
        self.drawView = GraphDrawView(viewModel: drawViewModel)
        
        super.init(frame: .zero)
        
        scrollView.delegate = self
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        drawView.backgroundColor = .clear
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
        
        subscribeToViewModel()
    }
    
    private func setSelectedIndexForX(_ x: CGFloat, limitToSelection: Bool = true) {
        guard let guides = drawViewModel.guides,
              let keyGuide = guides.keySeries else { return }
        let floatingOffset = keyGuide.floatingOffsetForX(x)
        let floatingBase = CGFloat(workoutViewModel.selectionRange.lowerBound)
        let floatingIndex = floatingBase + floatingOffset
        
        let fixedIndex: Int
        if limitToSelection {
            let workoutRange = workoutViewModel.keyedData[workoutViewModel.selectionRange]
            fixedIndex = workoutRange.bestClosedIndex(for: floatingIndex)
        } else {
            let workoutRange = workoutViewModel.keyedData
            fixedIndex = workoutRange.bestClosedIndex(for: floatingIndex)
        }
        workoutViewModel.selectionPoint = fixedIndex
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
            workoutViewModel.selectionPoint = nil
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateScrollViewForSelectedRange(
            keyedData: workoutViewModel.keyedData,
            selectedRange: workoutViewModel.selectionRange
        )
    }
    
    private func updateRange() {
        let keyedData = workoutViewModel.keyedData
        let percentStart = scrollView.contentOffset.x / scrollView.contentSize.width
        let length = CGFloat(keyedData.count) / scrollView.zoomScale
        
        let startIndex = keyedData.indexForPercent(percentStart)
        let endIndex = keyedData.bestHalfOpenIndex(for: CGFloat(startIndex) + length)
        let range = startIndex..<endIndex
        
        if workoutViewModel.selectionRange != range {
            workoutViewModel.selectionRange = range
        }
    }
    
    private func updateScrollViewForSelectedRange(keyedData: KeyedWorkoutData, selectedRange: Range<Int>) {
        let fullCount = keyedData.count
        
        scrollView.zoomScale = CGFloat(fullCount) / CGFloat(selectedRange.count)
        scrollView.contentOffset = CGPoint(
            x: scrollView.contentSize.width * CGFloat(selectedRange.lowerBound) / CGFloat(fullCount),
            y: 0
        )
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
