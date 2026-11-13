//
//  HealthMetricSummaryCardView+SubView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/01/2026.
//

import SwiftUI
import SharedModels
import ComposableArchitecture
import Charts

extension HealthMetricSummaryCardView {
    
    @ViewBuilder
    func blurredPlaceholderContent(for metric: HealthMetricType) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Value Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("–")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(metric.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("–:–")
                       .font(.caption)
                       .foregroundColor(.secondary)
                       .opacity(0.8)
                }
                
                // Status Label
                HStack(spacing: 4) {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text("No Data")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            
            placeholderChart(for: metric)
        }
        .padding(.vertical, 8)
        .blur(radius: 5)
        .overlay {
            VStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text(placeholderMessage(for: metric))
                    .foregroundColor(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    /// Status colours bottom-up, matching `TrainingComponentScore.statusBands`.
    private var placeholderBands: [ScoreStatus] {
        [.stronglyLowers, .lowers, .neutral, .raises, .stronglyRaises]
    }

    /// Why this tile is empty, in the same words the readiness card is using.
    ///
    /// Waiting for the night to close is not missing data, and telling the user to
    /// check the Health app over it sent them looking for a fault that is not there.
    private func placeholderMessage(for metric: HealthMetricType) -> String {
        guard store.isAwaitingSleepData else { return metric.missingDataMessage }

        return String(localized: "Waiting for sleep data", bundle: .main)
    }

    @ViewBuilder
    private func placeholderChart(for metric: HealthMetricType) -> some View {
        // Five bands in the status colours, so the blurred placeholder has the
        // same silhouette as the gauge it stands in for.
        Chart {
            ForEach(Array(placeholderBands.enumerated()), id: \.offset) { index, status in
                RectangleMark(
                    xStart: .value("X", 0),
                    xEnd: .value("X", 1),
                    yStart: .value("Y", index * 20),
                    yEnd: .value("Y", (index + 1) * 20)
                )
                .foregroundStyle(status.color.opacity(0.3))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 10, height: 80) // Match the gauge width
        .clipShape(RoundedRectangle(cornerRadius: 5)) // Match segment corner radius approximation
    }
    
    // Removed unused metricColor helper since we use fixed scale colors
}

// MARK: - Preview

#Preview {
    HealthMetricSummaryCardView(
        store: Store(
            initialState: HealthMetricSummaryCardFeature.State(
                contentState: .ready(.elite),
                components: TrainingReadinessComponents(
                    restingHeartRate: nil,
                    heartRateVariability: nil,
                    sleepQuality: nil,
                    previousDayLoad: nil
                )
            )
        ) {
            HealthMetricSummaryCardFeature()
        }
    )
    .padding()
    .background(Color.black)
}
