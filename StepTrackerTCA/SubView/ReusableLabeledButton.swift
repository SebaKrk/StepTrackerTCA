//
//  LabeledButton.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import SwiftUI

struct LabeledButton: View {
    
    var title: String
    var systemImage: String
    var tint: Color = .pink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding()
                .background(tint.opacity(0.1))
                .foregroundColor(tint)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint, lineWidth: 0.5)
        )
        .padding()
        .buttonStyle(.plain)
    }
}
