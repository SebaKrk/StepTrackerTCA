//
//  WidgetTitleFooterHour.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/01/2025.
//

import SwiftUI

struct WidgetTitleFooterHour: View {
    
    // MARK: - Properties
    
    let date: Date?
    let color: Color
    
    // MARK: - Lifecycle
    
    init(date: Date?, color: Color) {
        self.date = date
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Spacer()
            dateLabel
        }
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var dateLabel: some View {
        if let date = date {
            Text("\(date, format: .dateTime.hour().minute())")
                .foregroundStyle(color)
                .font(.caption)
                .bold()
        }
    }
    
}
