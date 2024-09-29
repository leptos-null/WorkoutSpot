//
//  KeyedWorkoutView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/26/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI
import CoreLocation

@dynamicMemberLookup
final class KeyedWorkoutViewModel: ObservableObject {
    struct Synced {
        let keyedData: KeyedWorkoutData
        var selectionPoint: Int?
        var selectionRange: Range<Int>
    }
    
    let analysis: WorkoutAnalysis
    
    @Published private(set) var synced: Synced
    
    var keyedData: KeyedWorkoutData {
        get { synced.keyedData }
        set {
            let oldValue = synced
            let oldKeyedData = oldValue.keyedData
            
            let newSelectionPoint = oldValue.selectionPoint
                .map { newValue.convertIndex($0, from: oldKeyedData) }
            
            let lowerBound = newValue.convertIndex(oldValue.selectionRange.first!, from: oldKeyedData)
            let upperBound = newValue.convertIndex(oldValue.selectionRange.last!, from: oldKeyedData)
            
            synced = .init(
                keyedData: newValue,
                selectionPoint: newSelectionPoint,
                selectionRange: Range(lowerBound...upperBound)
            )
        }
    }
    
    subscript<T>(dynamicMember member: KeyPath<Synced, T>) -> T {
        synced[keyPath: member]
    }
    
    subscript<T>(dynamicMember member: WritableKeyPath<Synced, T>) -> T {
        _read {
            yield synced[keyPath: member]
        }
        set(newValue) {
            synced[keyPath: member] = newValue
        }
    }
    
    init(analysis: WorkoutAnalysis) {
        self.analysis = analysis
        
        let keyedData = analysis.timeDomain
        self.synced = .init(
            keyedData: keyedData,
            selectionPoint: nil,
            selectionRange: keyedData.indices
        )
    }
    
    var annotationCoordinate: CLLocationCoordinate2D? {
        guard let indx = synced.selectionPoint else { return nil }
        return keyedData.coordinate?[indx]
    }
    
    private func percentIntoDistanceDomain(index: Int) -> CGFloat? {
        guard let distanceDomain = analysis.distanceDomain else { return nil }
        let indx = distanceDomain.convertIndex(index, from: keyedData)
        let total = distanceDomain.count
        return CGFloat(indx) / CGFloat(total)
    }
    
    var segmentStartUnit: CGFloat? {
        guard let rangeFirst = synced.selectionRange.first else { return nil }
        return percentIntoDistanceDomain(index: rangeFirst)
    }
    
    var segmentEndUnit: CGFloat? {
        guard let rangeLast = synced.selectionRange.last else { return nil }
        return percentIntoDistanceDomain(index: rangeLast)
    }
}

// with help from https://nilcoalescing.com/blog/AnchoredPositionInSwiftUI/
struct BoundedPosition: Layout {
    let proposedX: CGFloat?
    let proposedY: CGFloat?
    
    init(x: CGFloat? = nil, y: CGFloat? = nil) {
        proposedX = x
        proposedY = y
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxNeeded = subviews.reduce(into: CGSize.zero) { partialResult, subview in
            let subSize = subview.sizeThatFits(proposal)
            partialResult.width = max(partialResult.width, subSize.width)
            partialResult.height = max(partialResult.height, subSize.height)
        }
        return proposal.replacingUnspecifiedDimensions(by: maxNeeded)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let dimensions = subview.dimensions(in: proposal)
            
            let xCenter = proposedX ?? dimensions[HorizontalAlignment.center]
            let yCenter = proposedY ?? dimensions[VerticalAlignment.center]
            
            let midWidth = dimensions.width/2
            let midHeight = dimensions.height/2
            
            let x = max(bounds.minX + midWidth, min(xCenter, bounds.maxX - midWidth))
            let y = max(bounds.minY + midHeight, min(yCenter, bounds.maxY - midHeight))
            
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .center,
                proposal: ProposedViewSize(width: dimensions.width, height: dimensions.height)
            )
        }
    }
}

struct KeyedWorkoutView: View {
    @ObservedObject var viewModel: KeyedWorkoutViewModel
    @StateObject private var graphViewModel = GraphDrawViewModel()
    
    private let pointStatsViewRadius: CGFloat = 8
    private let horizontalInset: CGFloat = 4
    
    // the x position within `WorkoutGraphView`
    private var relativeSelectionPositionX: CGFloat? {
        guard let indx = viewModel.selectionPoint,
              let graphGuides = graphViewModel.guides,
              let keyGuide = graphGuides.keySeries else { return nil }
        return keyGuide.xForOffset(indx - graphGuides.data.startIndex)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if let coordinates = viewModel.keyedData.coordinate,
                   let startUnit = viewModel.segmentStartUnit,
                   let endUnit = viewModel.segmentEndUnit {
                    WorkoutMap(
                        coordinates: coordinates,
                        routeColor: .workoutFull,
                        segmentColor: .workoutSegment,
                        segmentStart: startUnit,
                        segmentEnd: endUnit,
                        annotationCoordinate: viewModel.annotationCoordinate
                    )
                    .padding(.bottom)
                }
                HStack {
                    WorkoutSegmentStatsView(viewModel: viewModel)
                        .padding(8)
                        .padding(.horizontal, 4)
                        .opacity((viewModel.selectionPoint == nil) ? 1 : 0)
                    Spacer()
                }
                .overlay {
                    if let indx = viewModel.selectionPoint, let relativeSelectionPositionX {
                        BoundedPosition(x: relativeSelectionPositionX) {
                            WorkoutPointStatsView(stats: viewModel.keyedData[indx])
                                .padding(8)
                                .padding(.horizontal, 4)
                                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: pointStatsViewRadius))
                        }
                        .padding(.horizontal, horizontalInset - pointStatsViewRadius)
                        /* apply a negative padding of the background corner radius.
                         this allows the corner to go out of bounds which results in
                         the rectangle below to never become disconnected from the background.
                         */
                    }
                }
                
                HStack(spacing: 6) {
                    WorkoutGraphView(
                        keyedWorkoutViewModel: viewModel,
                        graphDrawViewModel: graphViewModel
                    )
                    .padding(.top)
                    .background {
                        if let relativeSelectionPositionX {
                            GeometryReader { geometryProxy in
                                Rectangle()
                                    .frame(width: 4)
                                    .foregroundStyle(.ultraThickMaterial)
                                    .position(
                                        x: relativeSelectionPositionX,
                                        y: geometryProxy.size.height / 2
                                    )
                            }
                            .clipped()
                        }
                    }
                    VStack {
                        WorkoutExtremaStatsView(data: viewModel.keyedData[viewModel.selectionRange], extrema: .max)
                            .padding(.top, 8)
                        Spacer()
                        WorkoutExtremaStatsView(data: viewModel.keyedData[viewModel.selectionRange], extrema: .min)
                            .padding(.bottom, 8)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectionPoint = nil
            }
            .padding(.horizontal, horizontalInset)
            
            if let distanceDomain = viewModel.analysis.distanceDomain {
                Picker("Domain", selection: $viewModel.keyedData) {
                    Text("Time")
                        .tag(viewModel.analysis.timeDomain)
                    Text("Distance")
                        .tag(distanceDomain)
                }
                .pickerStyle(.segmented)
            }
            
            WorkoutGraphPreview(viewModel: viewModel)
                .frame(height: 36)
                .padding(.top, 2)
        }
    }
}

extension KeyedWorkoutData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }
    
    static func == (lhs: KeyedWorkoutData, rhs: KeyedWorkoutData) -> Bool {
        lhs === rhs
    }
}

extension CoordinateSeries: Equatable {
    static func == (lhs: CoordinateSeries, rhs: CoordinateSeries) -> Bool {
        lhs === rhs
    }
}
