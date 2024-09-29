//
//  WorkoutGraphPreview.swift
//  WorkoutSpot
//
//  Created by Leptos on 9/28/24.
//  Copyright © 2024 Leptos. All rights reserved.
//

import SwiftUI

struct WorkoutGraphPreview: View {
    @ObservedObject var viewModel: KeyedWorkoutViewModel
    
    @GestureState private var initialRange: Range<Int>?
    
    var body: some View {
        WorkoutGraphPlainView(data: viewModel.keyedData[...])
            .background(Color(uiColor: .workoutFull.withAlphaComponent(0.4)), ignoresSafeAreaEdges: [])
            .opacity(0.8)
            .overlay {
                GeometryReader { geometryProxy in
                    let totalCount = viewModel.keyedData.count
                    let containerWidth = geometryProxy.size.width
                    Color(uiColor: .workoutSegment)
                        .opacity(0.6)
                        .frame(width: containerWidth * CGFloat(viewModel.selectionRange.count) / CGFloat(totalCount))
                        .offset(x: containerWidth * CGFloat(viewModel.selectionRange.lowerBound) / CGFloat(totalCount))
                        .gesture(
                            DragGesture()
                                .updating($initialRange) { value, initialRange, transaction in
                                    // theoretically, this closure could be called more often
                                    // than `body` is called, so don't re-use the variables
                                    // declared at the `body` level
                                    let selectionRange: Range<Int>
                                    if let initialRange {
                                        selectionRange = initialRange
                                    } else {
                                        selectionRange = viewModel.selectionRange
                                        initialRange = selectionRange
                                    }
                                    
                                    let fullRangeCount = viewModel.keyedData.count
                                    let rangeCount = selectionRange.count
                                    let movePercent = value.translation.width / geometryProxy.size.width
                                    let proposedStart = max(0, selectionRange.lowerBound + Int(movePercent * CGFloat(fullRangeCount)))
                                    let startIndex = min(proposedStart, fullRangeCount - rangeCount)
                                    
                                    let proposedRange = startIndex..<(startIndex + rangeCount)
                                    assert(viewModel.keyedData.indices.contains(proposedRange))
                                    viewModel.selectionRange = proposedRange
                                }
                        )
                }
            }
    }
}

struct WorkoutGraphPlainView: UIViewRepresentable {
    let viewModel = GraphDrawViewModel()
    let data: KeyedWorkoutData.SubSequence
    
    func makeUIView(context: Context) -> GraphDrawView {
        let uiView = GraphDrawView(viewModel: viewModel)
        uiView.backgroundColor = .clear
        uiView.graphInsets = .init(top: 1, left: 1, bottom: 1, right: 1)
        return uiView
    }
    
    func updateUIView(_ uiView: GraphDrawView, context: Context) {
        uiView.data = data
    }
}
