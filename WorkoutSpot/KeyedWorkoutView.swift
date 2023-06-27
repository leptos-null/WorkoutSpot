//
//  KeyedWorkoutView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/26/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI
import CoreLocation

final class KeyedWorkoutViewModel: ObservableObject {
    let analysis: WorkoutAnalysis
    
    @Published var keyedData: KeyedWorkoutData {
        didSet {
            let newValue = keyedData
            
            if let selectionPoint {
                self.selectionPoint = newValue.convertIndex(selectionPoint, from: oldValue)
            }
            let lowerBound = newValue.convertIndex(selectionRange.lowerBound, from: oldValue)
            let upperBound = newValue.convertIndex(selectionRange.upperBound, from: oldValue)
            self.selectionRange = lowerBound..<upperBound
        }
    }
    
    @Published var selectionPoint: Int?
    @Published var selectionRange: Range<Int>
    
    init(analysis: WorkoutAnalysis) {
        self.analysis = analysis
        self.keyedData = analysis.timeDomain
        self.selectionPoint = nil
        self.selectionRange = analysis.timeDomain.indices
    }
    
    var annotationCoordinate: CLLocationCoordinate2D? {
        guard let selectionPoint else { return nil }
        return keyedData.coordinate[selectionPoint]
    }
    
    private func percentIntoDistanceDomain(index: Int) -> CGFloat {
        let distanceDomain = analysis.distanceDomain
        let indx = distanceDomain.convertIndex(index, from: keyedData)
        let total = distanceDomain.count
        return CGFloat(indx) / CGFloat(total)
    }
    
    var segmentStartUnit: CGFloat {
        percentIntoDistanceDomain(index: selectionRange.first!)
    }
    
    var segmentEndUnit: CGFloat {
        percentIntoDistanceDomain(index: selectionRange.last!)
    }
}

struct KeyedWorkoutView: View {
    @ObservedObject var viewModel: KeyedWorkoutViewModel
    
    var body: some View {
        WorkoutMap(
            coordinates: viewModel.keyedData.coordinate,
            routeColor: .systemIndigo,
            segmentColor: .systemGreen,
            segmentStart: viewModel.segmentStartUnit,
            segmentEnd: viewModel.segmentEndUnit,
            annotationCoordinate: viewModel.annotationCoordinate
        )
        
        WorkoutGraphView(
            keyedWorkoutViewModel: viewModel
        )
    }
}
