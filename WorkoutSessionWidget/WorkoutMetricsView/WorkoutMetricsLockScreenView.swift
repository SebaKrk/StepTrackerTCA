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
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    heartRateView
                    Spacer()
                    heartRateZoneView
                }
                heartRatePercentageView(48)
                activeEnergyView
                heartRateZoneDescriptionView
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 8) {
                hrStatCard(
                    title: "MAX HR",
                    value: "\(context.state.maxHeartRate)"
                )
                hrStatCard(
                    title: "AVG HR",
                    value: "\(context.state.averageHeartRate)"
                )
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: SubView
    
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

    private func hrStatCard(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
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
