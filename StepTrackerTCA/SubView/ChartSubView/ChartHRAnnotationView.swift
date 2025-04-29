//
//  ChartHRAnnotationView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 29/04/2025.
//

import SwiftUI

struct ChartHRAnnotationView: View {
    
    // MARK: - Properties
    
    let date: Date
    let valueOne: Double
    let valueTwo: Double
    let color: Color
    
    // MARK: - Lifecycle
    
    init(date: Date, valueOne: Double, valueTwo: Double, color: Color) {
        self.date = date
        self.valueOne = valueOne
        self.valueTwo = valueTwo
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
        )
    }
    
    // MARK: - Subview
    
    private var dateLabel: some View {
        Text(date, format: .dateTime.hour().minute())
    }
    
    private var valueLabel: some View {
        Group {
            HStack(spacing: 2) {
                Text(valueOne, format: .number)
                Text("-")
                Text(valueTwo, format: .number)
                Text("BMP")
                    .font(.caption2)
            }
        }
        .fontWeight(.heavy)
        .foregroundStyle(color)
    }
    
}
