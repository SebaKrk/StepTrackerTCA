//
//  WidgetHeaderView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/01/2025.
//

import SwiftUI

struct WidgetHeaderView: View {
    
    // MARK: - Properties
    
    let title: String
    let systemImage: String
    let date: Date?
    let color: Color
    var action: (() -> Void)?
    
    // MARK: - Lifecycle
    
    init(
        title: String,
        systemImage: String,
        date: Date? = nil,
        color: Color,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.date = date
        self.color = color
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            HStack {
                titleHeader
                Spacer()
                if let date = date {
                    dateTitleHeader(date)
                } else {
                    actionButton
                }
            }
            Divider()
        }
    }
    
    // MARK: - Subview
    
    var titleHeader: some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(color)
    }
    
    func dateTitleHeader(_ date: Date) -> some View {
        Text("\(date, format: .dateTime.month(.defaultDigits).day().year(.twoDigits))")
            .font(.caption)
            .foregroundStyle(color)
    }
    
    var actionButton: some View {
        Button {
            action?()
        } label: {
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(color)
    }
    
}
