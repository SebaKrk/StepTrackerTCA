//
//  ChartGroupBoxHeader.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import SwiftUI

struct ChartGroupBoxHeader: View {
    
    // MARK: - Properties
    
    let title: String
    let systemImage: String
    let secondaryText: String
    let color: Color
    let destination: Bool
    var action: (() -> Void)?
    
    // MARK: - Lifecycle
    
    init(
        title: String,
        systemImage: String,
        secondaryText: String,
        color: Color,
        destination: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.secondaryText = secondaryText
        self.color = color
        self.destination = destination
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                titleHeader
                secondaryTitleHeader
            }
            Spacer()
            if destination {
                actionButton
            }
        }
    }
    
    // MARK: - Subview
    
    var titleHeader: some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(color)
    }
    
    var secondaryTitleHeader: some View {
        Text(secondaryText)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    var actionButton: some View {
        Button {
            action?()
        } label: {
            Image(systemName: "chevron.right")
        }
    }
    
}
