//
//  MetricCardComponents.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import SwiftUI

/// Shared building blocks for the metric cards on the Activity Details screen.
/// Used by the dumb section views (energy, heart rate) and the
/// `PerformanceMetrics` child feature, so cards stay visually identical
/// across sections.
enum MetricCardGrid {

    /// Two flexible columns — the standard card grid of the details screen.
    static var twoColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]
    }
}

/// Big bold value with an optional trailing unit ("152 bpm", "486 kcal").
struct MetricCardValue: View {

    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Caption-sized icon + title used as every card's GroupBox label.
struct MetricCardLabel: View {

    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

/// Simple workout metric card with value and unit.
struct SimpleMetricCard: View {

    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        GroupBox {
            MetricCardValue(value: value, unit: unit)
        } label: {
            MetricCardLabel(title: title, icon: icon)
        }
        .styledGroupBox()
    }
}

/// Metric card with a tappable title (chevron) for navigation to details,
/// plus a colored classification sub-label under the value.
struct TappableMetricCard: View {

    let title: String
    let value: String
    let unit: String
    let label: String
    let labelColor: Color
    let icon: String
    let onTitleTap: () -> Void

    var body: some View {
        GroupBox {
            VStack(spacing: 4) {
                MetricCardValue(value: value, unit: unit)
                subLabel
            }
            .frame(minHeight: 50)
        } label: {
            titleButton
        }
        .styledGroupBox()
    }

    // MARK: - Implementation

    @ViewBuilder
    private var subLabel: some View {
        if !label.isEmpty {
            Text(label)
                .font(.caption)
                .foregroundColor(labelColor)
        }
    }

    private var titleButton: some View {
        Button {
            onTitleTap()
        } label: {
            HStack {
                MetricCardLabel(title: title, icon: icon)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
