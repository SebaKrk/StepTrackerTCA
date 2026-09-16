//
//  TreadmillTileView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import SharedModels
import SwiftUI

/// Live treadmill tile — a single-page sibling of `RunningTileView`: hero pace
/// with average pace / last km on the sides, distance in the header. No
/// carousel — machine runs don't need the rolling 5 km page, and there is no
/// GPS-derived data to page through.
///
/// Distance on a treadmill comes from motion sensors (Apple Watch); without a
/// Watch the source delivers nothing and every field renders as "—".
struct TreadmillTileView: View {

    // MARK: - Properties

    let metrics: WorkoutMetrics

    // MARK: - Body

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                header
                metricsRow
            }
        }
        .styledGroupBox()
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Spacer()
            distanceLabel
        }
    }

    private var metricsRow: some View {
        ZStack {
            heroPace
            HStack(alignment: .bottom) {
                sideMetric(speed: metrics.averageSpeed, label: "average pace")
                Spacer()
                sideMetric(speed: metrics.lastKilometerSpeed, label: "pace last km")
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 150)
        .padding(.bottom, 16)
    }

    // MARK: - SubView

    private var heroPace: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(PaceFormatter.text(fromMetersPerSecond: metrics.currentSpeed))
                .font(.system(size: 54, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: metrics.currentSpeed)
            Text(verbatim: "/km")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }

    private func sideMetric(speed: Double?, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(PaceFormatter.text(fromMetersPerSecond: speed))
                .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: speed)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var distanceLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("distance")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(PaceFormatter.distanceText(fromMeters: metrics.distance))
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: metrics.distance ?? 0))
                .animation(.snappy(duration: 0.3), value: metrics.distance)
        }
    }
}

#Preview("Treadmill tile") {
    TreadmillTileView(
        metrics: WorkoutMetrics(
            averageHeartRate: 142,
            heartRate: 146,
            activeEnergy: 280,
            distance: 3_150,
            currentSpeed: 2.78,
            averageSpeed: 2.7,
            lastKilometerSpeed: 2.82
        )
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Treadmill tile — no Watch (no data)") {
    TreadmillTileView(
        metrics: WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0)
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
