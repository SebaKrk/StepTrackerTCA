//
//  HealthMetricSummaryCardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

import ComposableArchitecture
import SwiftUI
import Charts
import SharedModels

@ViewAction(for: HealthMetricSummaryCardFeature.self)
struct HealthMetricSummaryCardView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthMetricSummaryCardFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .skeleton(isLoading: store.contentState == .loading)
            //.overlay { overlayContent }
            .onAppear {
                send(.viewDidAppear)
            }
            .subscriptionOverlay(
                 contentState: store.contentState,
                 subscriptionTier: store.subscriptionTier,
                 requiredTier: store.requiredTier,
                 onUnlockTapped: {
                     // send(.unlockButtonTapped)
                 },
                 onHealthAccessTapped: {
                     // send(.requestHealthAccessTapped)
                 },
                 onRetryTapped: {
                     // send(.retryButtonTapped)
                 })
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.details,
                    action: \.destination.details)) { store in
                        HealthMetricSummaryDetailsCardView(store: store)
                    }
    }
    
    private var rootView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            ForEach(HealthMetricType.allCases) { metricType in
                metricGroupBox(for: metricType, data: store.components?.score(for: metricType))
            }
        }
    }
    
    // MARK: - SubViews
    
    @ViewBuilder
    func metricGroupBox(
        for metric: HealthMetricType,
        data: TrainingComponentScore?
    ) -> some View {
        GroupBox {
            if let data = data {
                metricContent(for: metric, data: data)
            } else {
                blurredPlaceholderContent(for: metric)
            }
        } label: {
            containerTitle(metric, data: data)
        }
        .backgroundStyle(.clear)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
            .fill(Color(.secondarySystemBackground).gradient.opacity(0.5)))
        .frame(height: 160)
    }

    @ViewBuilder
    func metricContent(for metric: HealthMetricType, data: TrainingComponentScore) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                currentValueLabel(data)
                currentStatusLabel(for: metric, data: data)
            }
            Spacer()
            chartView(data)
        }
        .padding(.vertical, 8)
    }
    
    func currentValueLabel(_ data: TrainingComponentScore) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatValue(data.currentValue, unit: data.unit))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText(value: data.currentValue))
                    .animation(.snappy(duration: 0.3), value: data.currentValue)
                Text(data.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Timestamp - only for RHR and HRV (values that sync during the day)
            if let timestamp = data.timestamp,
               (data.unit == "bpm" || data.unit == "ms") {
                Text(formatTimestamp(timestamp))
                    .font(.caption)  // Slightly larger than caption2 for readability
                    .foregroundColor(.secondary)
                    .opacity(0.8)  // Subtle
            }
        }
    }
    
    func currentStatusLabel(for metric: HealthMetricType, data: TrainingComponentScore) -> some View {
        HStack(spacing: 4) {
            if metric == .activity, let activityStatus = data.asActivityStatus {
                Image(systemName: activityStatus.icon)
                    .foregroundColor(activityStatus.color)
                    .font(.caption)
                Text(activityStatus.title)
                    .font(.caption)
                    .foregroundColor(activityStatus.color)
            } else {
                Image(systemName: data.status.icon)
                    .foregroundColor(data.status.color)
                    .font(.caption)
                Text(data.status.text)
                    .font(.caption)
                    .foregroundColor(data.status.color)
            }
        }
    }
    
    func chartView(_ data: TrainingComponentScore) -> some View {
        Chart {
            metricChart(for: data)
        }
        .chartYScale(domain: data.minScore...data.maxScore)
        .chartXScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 10, height: 80)
    }
    
    @ViewBuilder
    func containerTitle(_ metricType: HealthMetricType, data: TrainingComponentScore?) -> some View {
        Button {
            if let data = data {
                send(.showDetailsButtonTapped(metric: metricType, data: data))
            }
        } label: {
            VStack {
                HStack {
                    Group {
                        Image(systemName: metricType.icon)
                        Text(metricType.title)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.gray)
                    .font(.caption)
                }
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)
    }
    
    // MARK: - Helpers
    
    /// Formats value based on unit type - kcal without decimals, others with 1 decimal
    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == "kcal" {
            return String(format: "%.0f", value)  // Calories: 652 (not 652.1)
        } else {
            return String(format: "%.1f", value)   // Others: 66.1 ms, 7.3 hours
        }
    }
    
    /// Formats timestamp to just time (8:07) for RHR and HRV cards
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.timeStyle = .short
        return formatter.string(from: date)  // Just "8:07", no "Dziś o"
    }
    
}
