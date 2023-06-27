//
//  UIView+Constraints.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/26/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import UIKit

extension UIView {
    func constrainEdges(equalTo other: UIView) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor),
            leftAnchor.constraint(equalTo: other.leftAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor),
            rightAnchor.constraint(equalTo: other.rightAnchor),
        ])
    }
}
