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
        return keyedData.coordinate[indx]
    }
    
    private func percentIntoDistanceDomain(index: Int) -> CGFloat {
        let distanceDomain = analysis.distanceDomain
        let indx = distanceDomain.convertIndex(index, from: keyedData)
        let total = distanceDomain.count
        return CGFloat(indx) / CGFloat(total)
    }
    
    var segmentStartUnit: CGFloat {
        percentIntoDistanceDomain(index: synced.selectionRange.first!)
    }
    
    var segmentEndUnit: CGFloat {
        percentIntoDistanceDomain(index: synced.selectionRange.last!)
    }
}

struct KeyedWorkoutView: View {
    @ObservedObject var viewModel: KeyedWorkoutViewModel
    @StateObject private var graphViewModel = GraphDrawViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                WorkoutMap(
                    coordinates: viewModel.keyedData.coordinate,
                    routeColor: .workoutFull,
                    segmentColor: .workoutSegment,
                    segmentStart: viewModel.segmentStartUnit,
                    segmentEnd: viewModel.segmentEndUnit,
                    annotationCoordinate: viewModel.annotationCoordinate
                )
                .padding(.bottom)
                
                HStack {
                    WorkoutSegmentStatsView(viewModel: viewModel)
                        .padding(8)
                        .padding(.horizontal, 4)
                        .opacity((viewModel.selectionPoint == nil) ? 1 : 0)
                    Spacer()
                }
                .overlay {
                    if let indx = viewModel.selectionPoint, let graphGuides = graphViewModel.guides {
                        GeometryReader { geometryProxy in
                            WorkoutPointStatsView(stats: viewModel.keyedData[indx])
                                .padding(8)
                                .padding(.horizontal, 4)
                                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .position(
                                    x: graphGuides.keySeries.xForOffset(indx - graphGuides.data.startIndex),
                                    y: geometryProxy.size.height / 2
                                )
                        }
                    }
                }
                
                WorkoutGraphView(
                    keyedWorkoutViewModel: viewModel,
                    graphDrawViewModel: graphViewModel
                )
                .padding(.top)
                .background {
                    if let indx = viewModel.selectionPoint, let graphGuides = graphViewModel.guides {
                        GeometryReader { geometryProxy in
                            Rectangle()
                                .frame(width: 4)
                                .foregroundStyle(.ultraThickMaterial)
                                .position(
                                    x: graphGuides.keySeries.xForOffset(indx - graphGuides.data.startIndex),
                                    y: geometryProxy.size.height / 2
                                )
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectionPoint = nil
            }
            
            Picker("Domain", selection: $viewModel.keyedData) {
                Text("Time")
                    .tag(viewModel.analysis.timeDomain)
                Text("Distance")
                    .tag(viewModel.analysis.distanceDomain)
            }
            .pickerStyle(.segmented)
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
