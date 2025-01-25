//
//  WidgetBodyContent.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/01/2025.
//

import SwiftUI

struct WidgetBodyContent: View {
    
    // MARK: - Properties
    
    let title: String
    let value: Double?
    let color: Color
    let isDestination: Bool
    let action: AnyView?
    
    // MARK: - Initializer
    
    init(
        title: String,
        value: Double? = nil,
        color: Color,
        isDestination: Bool = false,
        @ViewBuilder action: () -> AnyView? = { nil }
    ) {
        self.title = title
        self.value = value
        self.color = color
        self.isDestination = isDestination
        self.action = action()
    }
    
    // MARK: - Body
    
    var body: some View {
        widgetBody
    }
    
    @ViewBuilder
    private var widgetBody: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(.secondary)
                if isDestination, let action {
                    action
                } else if let value {
                    Text("\(value, format: .number.precision(.fractionLength(1))) kg")
                        .font(.title)
                        .bold()
                } else {
                    Text("No data available")
                }
            }
            Spacer()
        }
        .padding()
    }
    
}
