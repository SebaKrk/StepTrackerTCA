//
//  WorkoutSessionLiveActivity.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI
import SharedModels

struct WorkoutSessionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutSessionActivityAttributes.self) { context in
            
            WorkoutMetricsLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    heartRateBadge(context)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Link down (IOS-00098-G): metrics on screen are stale — show the
                    // indicator in place of the zone label instead of pretending live data.
                    if context.state.isWatchConnectionLost {
                        connectionLostBadge
                            .padding(.trailing, 4)
                    } else if showsStaleData(context) {
                        staleDataBadge
                            .padding(.trailing, 4)
                    } else {
                        zoneBadge(context)
                            .padding(.trailing, 4)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        percentageBadge(context)
                            .padding(.top, 4)

                        HStack {
                            energyBadge(context)
                            Spacer()
                            HStack(spacing: 8) {
                                avgHeartRateBadge(context)
                                maxHeartRateBadge(context)
                            }
                        }
                        .padding(.horizontal, 4)

                        // Pause + End buttons route through LiveActivityIntent →
                        // NotificationCenter → SessionFeature. Resume button is not shown
                        // because Activity ContentState lacks an `isPaused` flag.
                        controlButtons
                            .padding(.bottom, 4)
                    }
                }
                
            } compactLeading: {
                compactPercentageBadge(context)
            } compactTrailing: {
                if context.state.isWatchConnectionLost {
                    Image(systemName: "applewatch.slash")
                        .foregroundColor(.orange)
                } else if showsStaleData(context) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                } else {
                    compactHeartRateBadge(context)
                }
            } minimal: {
                compactPercentageBadge(context)
            }
            .keylineTint(keylineColor(context))
        }
        .contentMarginsDisabled()
    }

    /// Updates stopped arriving past the activity's `staleDate`.
    ///
    /// Deliberately separate from `isWatchConnectionLost`: that one means a Watch is
    /// gone and says so in orange. Staleness also covers a pause and an iPhone-only
    /// workout, where a Watch icon would name a device the session never had — so it
    /// stays neutral and claims only that the numbers are no longer fresh.
    private func showsStaleData(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> Bool {
        context.isStale && !context.state.isWatchConnectionLost
    }

    private func keylineColor(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> Color {
        if context.state.isWatchConnectionLost { return .orange }
        if showsStaleData(context) { return .gray }
        return context.state.heartRateZone.color
    }

    private var staleDataBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text(String(localized: "No data"))
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.gray)
    }
    
    // MARK: - Expanded Badges
    
    private func heartRateBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(Int(context.state.heartRate))",
            color: .white,
            style: .heartRate,
            suffix: "BPM"
        )
    }
    
    private func zoneBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        Text(context.state.heartRateZone.rawValue.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(context.state.heartRateZone.color)
    }

    private var connectionLostBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "applewatch.slash")
            Text(String(localized: "No link"))
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.orange)
    }
    
    private func percentageBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        Text("\(context.state.heartRatePercentage)%")
            .font(.system(size: 48, weight: .regular, design: .monospaced))
            .foregroundColor(.white)
    }
    
    private func energyBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(Int(context.state.activeEnergy))",
            color: .white,
            style: .energy,
            suffix: "KCAL"
        )
    }
    
    private func avgHeartRateBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(context.state.averageHeartRate)",
            color: .white.opacity(0.8),
            style: .plainValue,
            suffix: "AVG"
        )
    }
    
    private func maxHeartRateBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(context.state.maxHeartRate)",
            color: .white.opacity(0.8),
            style: .plainValue,
            suffix: "MAX"
        )
    }
    
    // MARK: - Control Buttons (Pause / End)

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button(intent: PauseWorkoutIntent()) {
                Image(systemName: "pause.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            Button(intent: EndWorkoutIntent()) {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Compact Badges
    
    private func compactPercentageBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(context.state.heartRatePercentage)",
            color: context.state.heartRateZone.color,
            style: .percentage
        )
    }
    
    private func compactHeartRateBadge(_ context: ActivityViewContext<WorkoutSessionActivityAttributes>) -> some View {
        MetricBadge(
            value: "\(Int(context.state.heartRate))",
            color: .white,
            style: .plainValue,
            suffix: "BPM"
        )
    }
    
}
