//
//  SaveWorkoutButton.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Mockup R6 — full-width glass save button, placed inline at the end of the
/// scroll (reached after reviewing the whole summary).
/// Tint is FIXED mint, never the zone accent — a red save reads as destructive.
struct SaveWorkoutButton: View {

    // MARK: - Properties

    let title: String
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        saveButton
    }

    // MARK: - Implementation

    private var saveButton: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .tint(SummaryTheme.mint)
        .disabled(!isEnabled)
        .padding(.top, 8)
    }
}

// MARK: - Previews

#Preview("SaveWorkoutButton — enabled / disabled") {
    VStack(spacing: 24) {
        SaveWorkoutButton(
            title: "Zapisz trening",
            isEnabled: true,
            action: {}
        )
        SaveWorkoutButton(
            title: "Zapisz trening",
            isEnabled: false,
            action: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
