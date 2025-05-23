//
//  SummaryMetricView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import SwiftUI

struct SummaryMetricView: View {
    
    // MARK: - Properties
    
    var title: String
    var value: String
    var valueColor: Color
    
    // MARK: - Lifecycle
    
    init(title: String, value: String, _ valueColor: Color) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    // MARK: - View
    
    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
            .foregroundStyle(valueColor)
        Divider()
    }
}
