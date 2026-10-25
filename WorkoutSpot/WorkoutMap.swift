//
//  WorkoutMap.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/21/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import MapKit
import SwiftUI

struct WorkoutMap<S: Sequence>: UIViewRepresentable where S: Equatable, S.Element == CLLocationCoordinate2D {
    var coordinates: S
    
    var routeColor: UIColor?
    var segmentColor: UIColor?
    
    var segmentStart: CGFloat
    var segmentEnd: CGFloat
    
    var annotationCoordinate: CLLocationCoordinate2D?
    
    var safeAreaInsets: EdgeInsets
    
    private func makePolyline() -> MKPolyline? {
        let result = coordinates.withContiguousStorageIfAvailable { buffer -> MKPolyline? in
            guard let baseAddress = buffer.baseAddress else { return nil }
            return MKPolyline(coordinates: baseAddress, count: buffer.count)
        }
        guard let result else {
            assertionFailure("\(S.self) did not provide ContiguousStorage")
            return nil
        }
        guard let result else {
            assertionFailure("coordinates did not have a baseAddress")
            return nil
        }
        return result
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        view.preferredConfiguration.elevationStyle = .realistic
        view.showsCompass = true
        view.showsScale = true
        return view
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        let matchingStaple: Coordinator.Staple
        if let staple = context.coordinator.staple, staple.coordinates == coordinates {
            matchingStaple = staple
        } else if let routeOverlay = makePolyline(),
                  let segmentOverlay = makePolyline() {
            let staple = Coordinator.Staple(
                coordinates: coordinates,
                routeOverlay: routeOverlay,
                routeRenderer: MKPolylineRenderer(polyline: routeOverlay),
                segmentOverlay: segmentOverlay,
                segmentRenderer: MKPolylineRenderer(polyline: segmentOverlay)
            )
            staple.routeRenderer.lineWidth = 6
            staple.segmentRenderer.lineWidth = 6
            
            if let previous = context.coordinator.staple {
                view.removeOverlays([ previous.routeOverlay, previous.segmentOverlay ])
            }
            
            context.coordinator.staple = staple
            
            view.addOverlays([ routeOverlay, segmentOverlay ])
            
            // hopefully `view.effectiveUserInterfaceLayoutDirection` matches `context.environment.layoutDirection`.
            // I decided to switch on the SwiftUI value, since the `safeAreaInsets` are coming in from SwiftUI
            let (safeAreaLeftInset, safeAreaRightInset): (CGFloat, CGFloat) = switch context.environment.layoutDirection {
            case .leftToRight: (safeAreaInsets.leading, safeAreaInsets.trailing)
            case .rightToLeft: (safeAreaInsets.trailing, safeAreaInsets.leading)
            @unknown default: (0, 0)
            }
            
            // `setVisibleMapRect` already takes `view.safeAreaInsets` into consideration (i.e. adds the safe area into the padding).
            // in my testing on iOS 27.0, `view.safeAreaInsets` is sometimes (incorrectly) all zeros.
            // to handle both cases (when `view.safeAreaInsets` is correct or all zeros),
            // add the SwiftUI reported safe area (which is correct), and then subtract off the `view.safeAreaInsets`.
            // the end result, after `setVisibleMapRect` adds back in `view.safeAreaInsets`,
            // is just the SwiftUI reported safe area.
            view.setVisibleMapRect(
                routeOverlay.boundingMapRect,
                edgePadding: UIEdgeInsets(
                    top: 32 + (safeAreaInsets.top - view.safeAreaInsets.top),
                    left: 18 + (safeAreaLeftInset - view.safeAreaInsets.left),
                    bottom: 32 + (safeAreaInsets.bottom - view.safeAreaInsets.bottom),
                    right: 18 + (safeAreaRightInset - view.safeAreaInsets.right)
                ),
                animated: true
            )
            
            matchingStaple = staple
        } else {
            return
        }
        matchingStaple.routeRenderer.strokeColor = routeColor
        
        matchingStaple.segmentRenderer.strokeColor = segmentColor
        matchingStaple.segmentRenderer.strokeStart = segmentStart
        matchingStaple.segmentRenderer.strokeEnd = segmentEnd
        
        let pointAnnotation = context.coordinator.pointAnnotation
        if let annotationCoordinate {
            pointAnnotation.coordinate = annotationCoordinate
            view.addAnnotation(pointAnnotation)
        } else {
            view.removeAnnotation(pointAnnotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        struct Staple {
            var coordinates: S
            
            var routeOverlay: MKPolyline
            var routeRenderer: MKPolylineRenderer
            
            var segmentOverlay: MKPolyline
            var segmentRenderer: MKPolylineRenderer
        }
        
        var staple: Staple?
        let pointAnnotation = MKPointAnnotation()
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let staple {
                if overlay === staple.routeOverlay {
                    return staple.routeRenderer
                }
                if overlay === staple.segmentOverlay {
                    return staple.segmentRenderer
                }
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
