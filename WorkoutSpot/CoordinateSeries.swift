//
//  CoordinateSeries.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/16/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import CoreLocation
import Accelerate

final class CoordinateSeries {
    typealias Element = CLLocationCoordinate2D
    typealias Index = Int
    
    private let data: UnsafeBufferPointer<Element>
    
    init<T: AccelerateBuffer, U: AccelerateBuffer>(values: T, keys: U, domainMagnitude: Int) where T.Element == Element, U.Element == Double {
        let interpolated = UnsafeMutableBufferPointer<Element>.allocate(capacity: domainMagnitude)
        
        let keyPaths: [WritableKeyPath<Element, Double>] = [
            \.latitude, \.longitude
        ]
        let elementStride = MemoryLayout<Element>.stride / MemoryLayout<Double>.stride
        
        values.withUnsafeBufferPointer { valuesBuff in
            keys.withUnsafeBufferPointer { keysBuff in
                guard let valuesBase = valuesBuff.baseAddress,
                      let keysBase = keysBuff.baseAddress,
                      let interpolateBase = interpolated.baseAddress else { return }
                
                for keyPath in keyPaths {
                    vDSP_vgenpD(
                        valuesBase.pointer(to: keyPath)!, elementStride,
                        keysBase, 1,
                        interpolateBase.pointer(to: keyPath)!, elementStride,
                        vDSP_Length(domainMagnitude), vDSP_Length(keysBuff.count)
                    )
                }
            }
        }
        
        data = UnsafeBufferPointer(interpolated)
    }
    
    convenience init<T: AccelerateBuffer, U: AccelerateBuffer, F: BinaryFloatingPoint>(values: T, keys: U, domainMagnitude: F) where T.Element == Element, U.Element == Double {
        self.init(values: values, keys: keys, domainMagnitude: Int(domainMagnitude.rounded(.awayFromZero)))
    }
    
    init(raw data: UnsafeBufferPointer<Element>) {
        self.data = data
    }
    
    convenience init(raw data: UnsafeMutableBufferPointer<Element>) {
        self.init(raw: UnsafeBufferPointer(data))
    }
    
    deinit {
        data.deallocate()
    }
}

extension CoordinateSeries {
    // the distance between each data point and the value before it.
    // the first value is always 0
    // func stepHeight() -> DataSeries {
    //
    // }
}

extension CoordinateSeries {
    // func convert(to domain: DataSeries) -> CoordinateSeries {
    //     assert(self.data.count == domain.data.count)
    //     guard let domainMagnitude = domain.last else {
    //         fatalError("domain is empty")
    //     }
    //     return CoordinateSeries(values: data, keys: domain.data, domainMagnitude: domainMagnitude)
    // }
}

extension CoordinateSeries: RandomAccessCollection {
    subscript(position: Index) -> Element {
        data[position]
    }
    
    var startIndex: Index { data.startIndex }
    var endIndex: Index { data.endIndex }
    var indices: Range<Index> { data.indices }
    var count: Int { data.count }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        try body(data)
    }
}
