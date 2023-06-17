//
//  DataSeries.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/16/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation
import Accelerate

final class DataSeries {
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

extension DataSeries {
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
        return data[resolved.upperBound] - data[resolved.lowerBound]
    }
}

extension DataSeries {
    func derivative() -> DataSeries {
        let derivativeLength = data.count - 1
        
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // values[i] = data[i + 1] - data[i]
        vDSP.subtract(data[1...], data[..<derivativeLength], result: &values)
        
        var keys = UnsafeMutableBufferPointer<Element>.allocate(capacity: derivativeLength)
        // [0.5, 1.5, 2.5, ... ]
        vDSP.formRamp(withInitialValue: 0.5, increment: 1, result: &keys)
        
        let result = DataSeries(values: values, keys: keys, domainMagnitude: data.count)
        
        keys.deallocate()
        values.deallocate()
        
        return result
    }
    
    // the difference between each data point and the value before it.
    // the first value is always 0
    func stepHeight() -> DataSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        values[0] = 0 // we could instead use `data[0]` so that `stairCase` could fully reconstruct this object
        // values[i] = data[i + 1] - data[i]
        vDSP.subtract(data[1...], data.dropLast(), result: &values[1...])
        return DataSeries(raw: values)
    }
    
    func stairCase() -> DataSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        
        vDSP.integrate(data, using: .runningSum, result: &values)
        // if `stepHeight` used `data[0]` instead of `0` as the initial value,
        // we could reconstruct the original data series using
        //   vDSP.add(data[0], values, result: &values)
        return DataSeries(raw: values)
    }
    
    func clipping(to range: ClosedRange<Element>) -> DataSeries {
        var values = UnsafeMutableBufferPointer<Element>.allocate(capacity: data.count)
        
        vDSP.clip(data, to: range, result: &values)
        return DataSeries(raw: values)
    }
}

extension DataSeries {
    func convert(to domain: DataSeries) -> DataSeries {
        assert(self.data.count == domain.data.count)
        guard let domainMagnitude = domain.last else {
            fatalError("domain is empty")
        }
        return DataSeries(values: data, keys: domain.data, domainMagnitude: domainMagnitude)
    }
}

extension DataSeries: RandomAccessCollection {
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

extension Slice<DataSeries> {
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
