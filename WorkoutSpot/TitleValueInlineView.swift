//
//  TitleValueInlineView.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/27/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import SwiftUI

struct TitleValueInlineView: View {
    private let titleProvider: () -> Text
    private let accessibilityLabelProvider: (() -> Text)?
    private let valueProvider: () -> Text
    
    init(titleProvider: @escaping () -> Text, accessibilityLabelProvider: (() -> Text)? = nil, valueProvider: @escaping () -> Text) {
        self.titleProvider = titleProvider
        self.accessibilityLabelProvider = accessibilityLabelProvider
        self.valueProvider = valueProvider
    }
    
    init<TitleType: StringProtocol, AccessibilityLabelType: StringProtocol>(title: TitleType, accessibilityLabel: AccessibilityLabelType, valueProvider: @escaping () -> Text) {
        self.init(titleProvider: {
            Text(title)
        }, accessibilityLabelProvider: {
            Text(accessibilityLabel)
        }, valueProvider: valueProvider)
    }
    
    init<S: StringProtocol>(title: S, valueProvider: @escaping () -> Text) {
        self.init(titleProvider: {
            Text(title)
        }, valueProvider: valueProvider)
    }
    
    var body: some View {
        let key = titleProvider()
        let value = valueProvider()
        Text("\(key): \(value)")
            .accessibilityLabel(accessibilityLabelProvider?() ?? key)
            .accessibilityValue(value)
    }
}
