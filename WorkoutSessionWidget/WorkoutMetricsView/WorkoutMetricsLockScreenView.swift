//
//  WorkoutMetricsLockScreenView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI
import SharedModels

struct WorkoutMetricsLockScreenView: View {

    // MARK: - Context

    let context: ActivityViewContext<WorkoutSessionActivityAttributes>

    // MARK: - Property

    @State private var heartbeatScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    heartRateView
                    Spacer()
                    // Link down (IOS-00098-G): the on-screen metrics are stale —
                    // instead of the zone we show an indicator, not pretending the data is live.
                    if context.state.isWatchConnectionLost {
                        connectionLostView
                    } else {
                        heartRateZoneView
                    }
                }
                heartRatePercentageView(48)
                activeEnergyView
                heartRateZoneDescriptionView
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
        }
        .styledGroupBox()
    }

    // MARK: SubView

    private var borderColor: Color {
        context.state.isWatchConnectionLost
            ? .orange.opacity(0.5)
            : context.state.heartRateZone.color.opacity(0.5)
    }

    private var connectionLostView: some View {
        HStack(spacing: 4) {
            Image(systemName: "applewatch.slash")
            Text(String(localized: "No link"))
        }
        .font(.body.weight(.semibold))
        .foregroundColor(.orange)
    }

    private var heartRateView: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.body)
                .symbolEffect(.pulse, options: .repeating)

            Text("\(Int(context.state.heartRate))")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text("bpm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var heartRateZoneView: some View {
        Text(context.state.heartRateZone.title.capitalized)
            .font(.body.weight(.semibold))
            .foregroundColor(context.state.heartRateZone.color)
    }

    private func heartRatePercentageView(_ fontSize: CGFloat) -> some View {
        Text("\(context.state.heartRatePercentage)%")
            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
            .foregroundStyle(.primary)

    }

    private var activeEnergyView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.pink)
                .font(.body)
            Text("\(Int(context.state.activeEnergy)) kcal")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.top, 2)
    }

    private var heartRateZoneDescriptionView: some View {
        Text(context.state.heartRateZone.description)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }

}

// MARK: - Previews

#Preview("Notification - Resting", as: .content, using: WorkoutSessionActivityAttributes.preview) {
    WorkoutSessionLiveActivity()
} contentStates: {
    WorkoutSessionActivityAttributes.ContentState.resting
}

#Preview("Notification - Aerobic", as: .content, using: WorkoutSessionActivityAttributes.preview) {
    WorkoutSessionLiveActivity()
} contentStates: {
    WorkoutSessionActivityAttributes.ContentState.aerobic
}

#Preview("Notification - Threshold", as: .content, using: WorkoutSessionActivityAttributes.preview) {
    WorkoutSessionLiveActivity()
} contentStates: {
    WorkoutSessionActivityAttributes.ContentState.threshold
}

#Preview("Notification - Anaerobic", as: .content, using: WorkoutSessionActivityAttributes.preview) {
    WorkoutSessionLiveActivity()
} contentStates: {
    WorkoutSessionActivityAttributes.ContentState.anaerobic
}
