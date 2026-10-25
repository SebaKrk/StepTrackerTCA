//
//  InYourPlansBadge.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import SwiftUI

/// Marks a shared plan that already has a copy in the user's Plans.
struct InYourPlansBadge: View {

    var body: some View {
        Label(title, systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.15), in: .capsule)
    }

    // MARK: - Text

    private let title = String(localized: "In Your Plans")
}
