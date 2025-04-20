//
//  ChartAnnotationView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import SwiftUI

struct ChartAnnotationView: View {
    
    // MARK: - Properties
    
    let date: Date
    let value: Double
    let color: Color
    
    // MARK: - Lifecycle
    
    init(date: Date, value: Double, color: Color) {
        self.date = date
        self.value = value
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            dateLabel
            valueLabel
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
    
    // MARK: - Subview
    
    private var dateLabel: some View {
        Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
            .font(.footnote.bold())
            .foregroundStyle(.secondary)
    }
    
    private var valueLabel: some View {
        Text(value, format: .number.precision(.fractionLength(1)))
            .fontWeight(.heavy)
            .foregroundStyle(color)
    }
    
}
