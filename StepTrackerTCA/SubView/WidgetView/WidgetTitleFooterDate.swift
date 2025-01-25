//
//  WidgetTitleFooterDate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/01/2025.
//

import SwiftUI

struct WidgetTitleFooterDate: View {
    
    // MARK: - Properties
    
    let date: Date
    let color: Color
    
    // MARK: - Lifecycle
    
    init(date: Date, color: Color) {
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
    
    private var dateLabel: some View {
        Text("\(date, format: .dateTime.month(.defaultDigits).day().year(.twoDigits))")
            .foregroundStyle(color)
            .font(.caption)
            .bold()
    }
    
}

