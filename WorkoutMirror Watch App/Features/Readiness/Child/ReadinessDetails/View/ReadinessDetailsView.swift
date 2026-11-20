//
//  ReadinessDetailsView.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Breakdown of a readiness snapshot into its four components.
///
/// Each row shows the measured value against its baseline and reveals
/// an explanation of the metric when tapped.
@ViewAction(for: ReadinessDetailsFeature.self)
struct ReadinessDetailsView: View {

    // MARK: - Properties

    let store: StoreOf<ReadinessDetailsFeature>

    // MARK: - View

    var body: some View {
        List {
            ForEach(HealthMetricType.allCases) { metric in
                metricButton(for: metric)
            }
        }
        .navigationTitle(String(localized: "Breakdown"))
        .animation(.default, value: store.expandedMetric)
    }

    // MARK: - Subviews

    private func metricButton(for metric: HealthMetricType) -> some View {
        Button {
            send(.metricTapped(metric))
        } label: {
            metricRow(for: metric)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func metricRow(for metric: HealthMetricType) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            rowTitle(for: metric)

            if let component = store.snapshot.result.components.score(for: metric) {
                rowValue(for: component)
                rowBaseline(for: component)
            } else {
                missingValue(for: metric)
            }

            explanation(for: metric)
        }
    }

    private func rowTitle(for metric: HealthMetricType) -> some View {
        Label(metric.fullName, systemImage: metric.icon)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func rowValue(for component: TrainingComponentScore) -> some View {
        Text("\(Int(component.currentValue.rounded())) \(component.unit)")
            .font(.headline)
            .foregroundStyle(component.status.color)
    }

    @ViewBuilder
    private func rowBaseline(for component: TrainingComponentScore) -> some View {
        if let baseline = component.baselineValue {
            Text(String(
                localized: "7-day average: \(Int(baseline.rounded())) \(component.unit)"
            ))
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private func missingValue(for metric: HealthMetricType) -> some View {
        Text(metric.missingDataMessage)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private func explanation(for metric: HealthMetricType) -> some View {
        if store.expandedMetric == metric {
            Text(metric.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}
