//
//  GraphGuide.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/25/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit
import Accelerate

final class GraphConfig {
    let size: CGSize
    let graphInsets: UIEdgeInsets
    
    let effectiveSize: CGSize
    let filter: UnsafeBufferPointer<Double>
    
    init(dataCount: Int, size: CGSize, graphInsets: UIEdgeInsets = .zero, smoothingCoefficient: CGFloat = 3) {
        self.size = size
        self.graphInsets = graphInsets
        
        let effectiveSize = CGSize(
            width: size.width - (graphInsets.left + graphInsets.right),
            height: size.height - (graphInsets.top + graphInsets.bottom)
        )
        
        let minFactor = smoothingCoefficient * CGFloat(dataCount) / effectiveSize.width
        let factor = Int(minFactor.rounded(.up))
        
        var filter = UnsafeMutableBufferPointer<Double>.allocate(capacity: factor)
        vDSP.fill(&filter, with: 1/Double(factor))
        
        self.effectiveSize = effectiveSize
        self.filter = UnsafeBufferPointer(filter)
    }
    
    deinit {
        filter.deallocate()
    }
}

final class GraphGuide {
    typealias ValueType = Double
    /// The size of the graph
    let size: CGSize
    /// Insets within `size` to draw the graph
    let insets: UIEdgeInsets
    /// The `size` after applying `insets`
    let effectiveSize: CGSize
    /// A Bezier path which represents this graph
    ///
    /// - warning: Do not mutate this path
    let path: UIBezierPath
    /// The minimum value represented in this graph
    ///
    /// This value may be different from the minimum value
    /// of the provided series due to smoothing
    let minimumValue: ValueType
    /// The maximum value represented in this graph
    ///
    /// This value may be different from the maximum value
    /// of the provided series due to smoothing
    let maximumValue: ValueType
    
    private let decimatedData: [ValueType]
    private let decimationFactor: Int
    
    private let xScale: CGFloat
    private let yScale: CGFloat
    
    init<T: AccelerateBuffer>(series: T, config: GraphConfig) where T.Element == ValueType {
        self.size = config.size
        self.insets = config.graphInsets
        self.effectiveSize = config.effectiveSize
        
        let decimationFactor = config.filter.count
        
        let desamp = vDSP.downsample(series, decimationFactor: decimationFactor, filter: config.filter)
        
        var min: ValueType = vDSP.minimum(desamp)
        var max: ValueType = vDSP.maximum(desamp)
        
        if min.isZero && max.isZero {
            min = -1
            max = +1
        } else if (max - min) < .ulpOfOne {
            let scale: ValueType = 0.01 // relatively small value, but not too small
            let awayFromZero = 1 + scale
            let closerToZero = 1 - scale
            max *= (max > 0) ? awayFromZero : closerToZero
            min *= (min > 0) ? closerToZero : awayFromZero
        }
        
        let xScale = config.effectiveSize.width / CGFloat(desamp.count)
        let yScale = config.effectiveSize.height / (max - min)
        
        let points = UnsafeMutableBufferPointer<CGPoint>.allocate(capacity: desamp.count)
        if let pointsBaseAddress = points.baseAddress {
            let pointStride = MemoryLayout<CGPoint>.stride / MemoryLayout<Double>.stride
            let pointCount = vDSP_Length(points.count)
            
            var xRampBase: Double = insets.left
            var xRampSlope: Double = xScale
            // pointsBaseAddress[n].x = xRampBase + n * xRampSlope
            vDSP_vrampD(
                &xRampBase, &xRampSlope,
                pointsBaseAddress.pointer(to: \.x.native)!, pointStride,
                pointCount
            )
            
            let scaledMin = min * yScale
            var yBase: Double = config.size.height - config.graphInsets.bottom + scaledMin
            var yScaleNegative: Double = -yScale
            // pointsBaseAddress[n].y = desamp[n] * yScaleNegative + yBase
            vDSP_vsmsaD(
                desamp, 1,
                &yScaleNegative, &yBase,
                pointsBaseAddress.pointer(to: \.y.native)!, pointStride,
                pointCount
            )
        }
        
        let path = UIBezierPath()
        points.forEach { point in
            if path.isEmpty {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        points.deallocate()
        
        self.path = path
        
        self.minimumValue = min
        self.maximumValue = max
        self.decimatedData = desamp
        self.decimationFactor = decimationFactor
        
        self.xScale = xScale
        self.yScale = yScale
    }
    
    private func xForDecimatedIndex(_ index: Int) -> CGFloat {
        xForDecimatedIndex(CGFloat(index))
    }
    
    private func xForDecimatedIndex(_ index: CGFloat) -> CGFloat {
        index * xScale + insets.left
    }
    
    /// The `y` coordinate for the given value
    func yForValue(_ value: ValueType) -> CGFloat {
        size.height - insets.bottom - (value - minimumValue) * yScale
    }
    
    /// The value represented at coordinate `x`
    ///
    /// If `x` is outside of the graph, the nearest value is returned
    func valueForX(_ x: CGFloat) -> ValueType {
        let decimatedIndex = (x - insets.left) / xScale
        // linear interpolation
        let floor = decimatedIndex.rounded(.down)
        let ceil = decimatedIndex.rounded(.up)
        
        let fraction = decimatedIndex - floor
        
        let intFloor = Int(floor)
        let intCeil = Int(ceil)
        
        if intFloor < decimatedData.indices.first! { return decimatedData.first! }
        if intCeil > decimatedData.indices.last! { return decimatedData.last! }
        
        let lo = decimatedData[intFloor]
        let hi = decimatedData[intCeil]
        let range = hi - lo
        let slide = range * fraction
        
        return lo + slide
    }
    
    /// `y` coordinate for the given `x` coordinate
    func yForX(_ x: CGFloat) -> CGFloat {
        yForValue(valueForX(x))
    }
    
    /// `x` coordinate for the point that represents `series[offset]`
    func xForOffset(_ offset: Int) -> CGFloat {
        let index = CGFloat(offset) / CGFloat(decimationFactor)
        return xForDecimatedIndex(index)
    }
    /// The offset within series
    func floatingOffsetForX(_ x: CGFloat) -> CGFloat {
        let index = (x - insets.left) / xScale
        return index * CGFloat(decimationFactor)
    }
}

@dynamicMemberLookup
class GraphGuides<DataSource, Series: AccelerateBuffer> where Series.Element == GraphGuide.ValueType {
    let data: DataSource
    let config: GraphConfig
    
    private var cache: [KeyPath<DataSource, Series>: GraphGuide] = [:]
    
    init(data: DataSource, config: GraphConfig) {
        self.data = data
        self.config = config
    }
    
    subscript(dynamicMember member: KeyPath<DataSource, Series>) -> GraphGuide {
        if let cached = cache[member] {
            return cached
        }
        let series = data[keyPath: member]
        let graphGuide = GraphGuide(series: series, config: config)
        cache[member] = graphGuide
        return graphGuide
    }
}
