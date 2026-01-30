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
                Text(metric.missingDataMessage)
                    .foregroundColor(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    @ViewBuilder
    private func placeholderChart(for metric: HealthMetricType) -> some View {
        Chart {
            // Mimic the 4-segment gauge scale
            RectangleMark(
                xStart: .value("X", 0), xEnd: .value("X", 1),
                yStart: .value("Y", 0), yEnd: .value("Y", 25)
            )
            .foregroundStyle(.red.opacity(0.3))
            
            RectangleMark(
                xStart: .value("X", 0), xEnd: .value("X", 1),
                yStart: .value("Y", 25), yEnd: .value("Y", 50)
            )
            .foregroundStyle(.orange.opacity(0.3))
            
            RectangleMark(
                xStart: .value("X", 0), xEnd: .value("X", 1),
                yStart: .value("Y", 50), yEnd: .value("Y", 75)
            )
            .foregroundStyle(.yellow.opacity(0.3))
            
            RectangleMark(
                xStart: .value("X", 0), xEnd: .value("X", 1),
                yStart: .value("Y", 75), yEnd: .value("Y", 100)
            )
            .foregroundStyle(.green.opacity(0.3))
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
