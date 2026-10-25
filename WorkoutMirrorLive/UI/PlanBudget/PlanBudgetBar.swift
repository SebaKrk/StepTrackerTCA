//
//  PlanBudgetBar.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import SwiftUI

/// Plan length against the class target: "45 of 60 min" with a bar, "+15 min" when longer.
struct PlanBudgetBar: View {

    let totalMinutes: Int
    let targetMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            bar
        }
    }

    // MARK: - Implementation

    private var header: some View {
        HStack {
            Text(String(localized: "\(totalMinutes) of \(targetMinutes) min"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Spacer()
            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
        }
    }

    private var bar: some View {
        ProgressView(value: Double(min(totalMinutes, targetMinutes)), total: Double(max(targetMinutes, 1)))
            .tint(statusColor)
    }

    private var isShort: Bool {
        totalMinutes < targetMinutes
    }

    private var statusText: String {
        if isShort {
            return String(localized: "\(targetMinutes - totalMinutes) min missing")
        }
        let extra = totalMinutes - targetMinutes
        return extra > 0 ? String(localized: "+\(extra) min") : String(localized: "Full class")
    }

    private var statusColor: Color {
        isShort ? .orange : .green
    }
}
