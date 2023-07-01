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
    
    static func lerp(_ p_1: Element, _ p_2: Element, t: Double) -> Element {
        // fast paths
        if t == 0 { return p_1 }
        if t == 1 { return p_2 }
        
        let degToRad: Double = .pi / 180
        let phi_1 = p_1.latitude * degToRad, lambda_1 = p_1.longitude * degToRad,
            phi_2 = p_2.latitude * degToRad, lambda_2 = p_2.longitude * degToRad
        
        // https://en.wikipedia.org/wiki/Great-circle_navigation
        
        let lambda_12 = lambda_2 - lambda_1
        let alpha_1 = atan2(
            cos(phi_2) * sin(lambda_12),
            +cos(phi_1) * sin(phi_2) - sin(phi_1) * cos(phi_2) * cos(lambda_12)
        )
        
        let alpha_2 = atan2(
            cos(phi_1) * sin(lambda_12),
            -cos(phi_2) * sin(phi_1) + sin(phi_2) * cos(phi_1) * cos(lambda_12)
        )
        
        let alpha_0 = atan2(
            sin(alpha_1) * cos(phi_1),
            sqrt(pow(cos(alpha_1), 2) + pow(sin(alpha_1), 2) * pow(sin(phi_1), 2))
        )
        
        let sigma_01 = atan2(tan(phi_1), cos(alpha_1))
        let sigma_02 = atan2(tan(phi_2), cos(alpha_2))
        
        let lambda_0 = lambda_1 - atan2(
            sin(alpha_0) * sin(sigma_01),
            cos(sigma_01)
        )
        
        // https://en.wikipedia.org/wiki/Linear_interpolation#Programming_language_support
        let sigma = (1 - t) * sigma_01 + t * sigma_02
        let phi = atan2(
            cos(alpha_0) * sin(sigma),
            sqrt(pow(cos(sigma), 2) + pow(sin(alpha_0), 2) * pow(sin(sigma), 2))
        )
        let lambda = atan2(
            sin(alpha_0) * sin(sigma),
            cos(sigma)
        ) + lambda_0
        
        return Element(
            latitude: phi / degToRad,
            longitude: lambda / degToRad
        )
    }
    
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
    func stepHeight() -> ScalarSeries {
        let length = data.count
        // https://en.wikipedia.org/wiki/Earth_radius#Fixed_radius
        let a: Double = 6378137 // meters (semi-major radius)
        let b: Double = 6356752 // meters (semi-minor radius)
        
        let aRaiseTwo = a * a // a^2
        let aRaiseFour = aRaiseTwo * aRaiseTwo // a^4
        
        let bRaiseTwo = b * b // b^2
        let bRaiseFour = bRaiseTwo * bRaiseTwo // b^4
        
        let continuousRad = UnsafeMutablePointer<Double>.allocate(capacity: length * 2) // radians
        let latRad = continuousRad.advanced(by: length * 0) // latitude in radians
        let lngRad = continuousRad.advanced(by: length * 1) // longitude in radians
        
        let continuousRadBuff = UnsafeBufferPointer(start: continuousRad, count: length * 2) // radians
        
        let latSinCos = UnsafeMutableBufferPointer<Double>.allocate(capacity: length * 2) // sin(latitude), cos(latitude)
        var latSin = latSinCos[(length*0)..<(length*1)] // sin(latitude)
        var latCos = latSinCos[(length*1)..<(length*2)] // cos(latitude)
        
        if let coordinateBase = data.baseAddress {
            let elementStride = MemoryLayout<Element>.stride / MemoryLayout<Double>.stride
            var degToRad: Double = .pi / 180
            // latRad[n] = rad(from: data[n].latitude)
            vDSP_vsmulD(coordinateBase.pointer(to: \.latitude)!, elementStride, &degToRad, latRad, 1, vDSP_Length(length))
            // lngRad[n] = rad(from: data[n].longitude)
            vDSP_vsmulD(coordinateBase.pointer(to: \.longitude)!, elementStride, &degToRad, lngRad, 1, vDSP_Length(length))
        }
        
        // latSin[n] = sin(latRad[n])
        // latCos[n] = cos(latRad[n])
        vForce.sincos(
            UnsafeBufferPointer(start: latRad, count: length),
            sinResult: &latSin,
            cosResult: &latCos
        )
        
        var latSinSqCosSq = UnsafeMutableBufferPointer<Double>.allocate(capacity: length * 2) // sin^2(latitude), cos^2(latitude)
        let latSinSq = latSinSqCosSq[(length*0)..<(length*1)] // sin^2(latitude)
        let latCosSq = latSinSqCosSq[(length*1)..<(length*2)] // cos^2(latitude)
        
        // latSinSqCosSq[n] = latSinCos[n]
        // which is memory mapped to:
        //   latSinSq = latSin^2
        //   latCosSq = latCos^2
        vDSP.square(latSinCos, result: &latSinSqCosSq)
        
        var radiusNum = UnsafeMutableBufferPointer<Double>.allocate(capacity: length)
        vDSP.add(
            multiplication: (latCosSq, aRaiseFour),
            multiplication: (latSinSq, bRaiseFour),
            result: &radiusNum
        )
        
        var radiusDenom = UnsafeMutableBufferPointer<Double>.allocate(capacity: length)
        vDSP.add(
            multiplication: (latCosSq, aRaiseTwo),
            multiplication: (latSinSq, bRaiseTwo),
            result: &radiusDenom
        )
        
        var radii = UnsafeMutableBufferPointer<Double>.allocate(capacity: length)
        vDSP.divide(radiusNum, radiusDenom, result: &radii)
        vForce.sqrt(radii, result: &radii)
        
        var radAverage = UnsafeMutableBufferPointer<Double>.allocate(capacity: length * 2)
        vDSP.multiply(
            subtraction: (continuousRadBuff.dropFirst(), continuousRadBuff.dropLast()),
            0.5, result: &radAverage[1...]
        )
        radAverage[length * 0] = 0
        radAverage[length * 1] = 0 // this is the point where `averageSpacing[n] = lngRad[0] - latRad[n - 1]`
        
        // sin(0) = 0 so we don't have to worry about the two cases above
        vForce.sin(radAverage, result: &radAverage)
        vDSP.square(radAverage, result: &radAverage)
        
        let latAverage = radAverage[(length*0)..<(length*1)]
        let lngAverage = radAverage[(length*1)..<(length*2)]
        
        var values = UnsafeMutableBufferPointer<Double>.allocate(capacity: length)
        values[0] = 0
        vDSP.multiply(latCos.dropFirst(), latCos.dropLast(), result: &values[1...])
        vDSP.add(multiplication: (values, lngAverage), latAverage, result: &values)
        vForce.sqrt(values.dropFirst(), result: &values[1...])
        vForce.asin(values.dropFirst(), result: &values[1...])
        vDSP.multiply(addition: (radii.dropFirst(), radii.dropLast()), values.dropFirst(), result: &values[1...])
        
        radAverage.deallocate()
        radii.deallocate()
        radiusDenom.deallocate()
        radiusNum.deallocate()
        
        latSinSqCosSq.deallocate()
        latSinCos.deallocate()
        continuousRad.deallocate()
        
        return ScalarSeries(raw: values)
    }
}

extension CoordinateSeries {
    func convert(to domain: ScalarSeries) -> CoordinateSeries {
        guard let domainMagnitude = domain.last else {
            fatalError("domain is empty")
        }
        return CoordinateSeries(values: data, keys: domain, domainMagnitude: domainMagnitude)
    }
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

extension CoordinateSeries: AccelerateBuffer {
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        try body(data)
    }
}
