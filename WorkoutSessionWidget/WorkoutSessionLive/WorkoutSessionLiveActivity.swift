//
//  WorkoutSessionLiveActivity.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

import ActivityKit
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
                        .padding(.leading, 16)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    zoneBadge(context)
                        .padding(.trailing, 16)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        percentageBadge(context)
                            .padding(.top, 8)
                        
                        HStack {
                            energyBadge(context)
                            Spacer()
                            HStack(spacing: 8) {
                                avgHeartRateBadge(context)
                                maxHeartRateBadge(context)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
                
            } compactLeading: {
                compactPercentageBadge(context)
            } compactTrailing: {
                compactHeartRateBadge(context)
            } minimal: {
                compactPercentageBadge(context)
            }
            .keylineTint(context.state.heartRateZone.color)
        }
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
