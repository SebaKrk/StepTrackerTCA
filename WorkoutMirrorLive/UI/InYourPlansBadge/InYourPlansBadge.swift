//
//  InYourPlansBadge.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import SwiftUI

/// Marks a shared plan that already has a copy in the user's Plans — full label when it fits, icon otherwise.
struct InYourPlansBadge: View {

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullBadge
            iconBadge
        }
    }

    // MARK: - Implementation

    private var fullBadge: some View {
        Label(title, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.15), in: .capsule)
    }

    private var iconBadge: some View {
        Image(systemName: iconName)
            .font(.body.weight(.semibold))
            .foregroundStyle(.green)
            .accessibilityLabel(title)
    }

    // MARK: - Text

    private let iconName = "checkmark.circle.fill"
    private let title = String(localized: "In Your Plans")
}
