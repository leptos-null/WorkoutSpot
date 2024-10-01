//
//  ScalarSeries.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/16/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import Accelerate

final class ScalarSeries {
    typealias Element = Double
    typealias Index = Int
    
    private let data: UnsafeBufferPointer<Element>
    
    init<T: AccelerateBuffer, U: AccelerateBuffer>(values: T, keys: U, domainMagnitude: Int) where T.Element == Element, U.Element == Element {
        var interpolated = UnsafeMutableBufferPointer<Element>.allocate(capacity: domainMagnitude)
        vDSP.linearInterpolate(values: values, atIndices: keys, result: &interpolated)
        data = UnsafeBufferPointer(interpolated)
    }
    
    convenience init<T: AccelerateBuffer, U: AccelerateBuffer, F: BinaryFloatingPoint>(values: T, keys: U, domainMagnitude: F) where T.Element == Element, U.Element == Element {
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

extension ScalarSeries {
    func average<R: RangeExpression>(over range: R) -> Element where R.Bound == Index {
        vDSP.mean(data[range])
    }
    
    func maximum<R: RangeExpression>(over range: R) -> Element where R.Bound == Index {
        vDSP.maximum(data[range])
    }
    
    func minimum<R: RangeExpression>(over range: R) -> Element where R.Bound == Index {
        vDSP.minimum(data[range])
    }
    
    func delta<R: RangeExpression>(over range: R) -> Element where R.Bound == Index {
        let resolved = range.relative(to: data)
        guard let lastIndex = resolved.last,
              let firstIndex = resolved.first else { return 0 } // empty, no change
        return data[lastIndex] - data[firstIndex]
    }
}

extension ScalarSeries {
    func derivative() -> ScalarSeries {
        let derivativeLength = data.count - 1
        
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // values[i] = data[i + 1] - data[i]
        vDSP.subtract(data.dropFirst(), data.dropLast(), result: &values)
        
        var keys = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // [0.5, 1.5, 2.5, ... ]
        vDSP.formRamp(withInitialValue: 0.5, increment: 1, result: &keys)
        
        let result = ScalarSeries(values: values, keys: keys, domainMagnitude: data.count)
        
        keys.deallocate()
        values.deallocate()
        
        return result
    }
    
    // the distance between each data point and the value before it.
    // the first value is always 0
    func stepHeight() -> ScalarSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        values[0] = 0 // we could instead use `data[0]` so that `stairCase` could fully reconstruct this object
        // values[i] = data[i + 1] - data[i]
        vDSP.subtract(data[1...], data.dropLast(), result: &values[1...])
        return ScalarSeries(raw: values)
    }
    
    func stairCase() -> ScalarSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        
        vDSP.integrate(data, using: .runningSum, result: &values)
        // if `stepHeight` used `data[0]` instead of `0` as the initial value,
        // we could reconstruct the original data series using
        //   vDSP.add(data[0], values, result: &values)
        return ScalarSeries(raw: values)
    }
    
    func clipping(to range: ClosedRange<Element>) -> ScalarSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        
        vDSP.clip(data, to: range, result: &values)
        return ScalarSeries(raw: values)
    }
}

extension ScalarSeries {
    func derivative(in domain: ScalarSeries) -> ScalarSeries {
        let derivativeLength = data.count - 1
        
        var dy = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // dy[i] = data[i + 1] - data[i]
        vDSP.subtract(self.data.dropFirst(), self.data.dropLast(), result: &dy)
        
        var dx = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // dx[i] = data[i + 1] - data[i]
        vDSP.subtract(domain.data.dropFirst(), domain.data.dropLast(), result: &dx)
        
        var keys = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // [0.5, 1.5, 2.5, ... ]
        vDSP.formRamp(withInitialValue: 0.5, increment: 1, result: &keys)
        
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        vDSP.divide(dy, dx, result: &values)
        
        let filteredValues = vDSP.compress(values, gatingVector: dx, nonZeroGatingCount: nil)
        let filteredKeys = vDSP.compress(keys, gatingVector: dx, nonZeroGatingCount: nil)
        
        values.deallocate()
        keys.deallocate()
        dx.deallocate()
        dy.deallocate()
        
        let result = ScalarSeries(values: filteredValues, keys: filteredKeys, domainMagnitude: data.count)
        
        return result
    }
    
    func convert(to domain: ScalarSeries) -> ScalarSeries {
        guard let domainMagnitude = domain.last else {
            fatalError("domain is empty")
        }
        return ScalarSeries(values: data, keys: domain, domainMagnitude: domainMagnitude)
    }
}

extension ScalarSeries: RandomAccessCollection {
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

extension Slice<ScalarSeries> {
    func average() -> Element {
        base.average(over: indices)
    }
    
    func maximum() -> Element {
        base.maximum(over: indices)
    }
    
    func minimum() -> Element {
        base.minimum(over: indices)
    }
    
    func delta() -> Element {
        base.delta(over: indices)
    }
}

extension ScalarSeries: AccelerateBuffer {
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        try body(data)
    }
}
