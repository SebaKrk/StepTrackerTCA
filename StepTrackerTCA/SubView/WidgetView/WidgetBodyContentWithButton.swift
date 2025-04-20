//
//  WidgetBodyContentWithButton.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//


import SwiftUI

struct WidgetBodyContentWithButton: View {
    
    // MARK: - Properties
    
    let title: String
    let value: Double?
    let color: Color
    let action: AnyView?
    
    // MARK: - Initializer
    
    init(
        title: String,
        value: Double? = nil,
        color: Color,
        @ViewBuilder action: () -> AnyView? = { nil }
    ) {
        self.title = title
        self.value = value
        self.color = color
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
                    .font(.footnote)
                if let value {
                    Text("\(value, format: .number.precision(.fractionLength(1))) kg")
                        .font(.title)
                        .bold()
                } else {
                    action
                }
            }
            Spacer()
        }
        .padding()
    }
    
}
