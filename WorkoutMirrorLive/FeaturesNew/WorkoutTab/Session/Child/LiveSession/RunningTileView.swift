//
//  RunningTileView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import SharedModels
import SwiftUI

/// Live outdoor-running tile — hero pace (min/km) with distance in the header
/// and a swipeable pair of stat pages. Dumb view: metrics come in whole, page
/// selection goes out through the binding (state lives in `LiveSessionFeature`).
///
/// Fields the current data source cannot measure stay `nil` and render as "—",
/// so the tile adapts to the workout path without knowing which one is active.
struct RunningTileView: View {

    // MARK: - Properties

    let metrics: WorkoutMetrics
    @Binding var currentPage: DistanceTilePage

    // MARK: - Body

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                header
                pages
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

    private var pages: some View {
        TabView(selection: $currentPage) {
            overviewPage
                .tag(DistanceTilePage.overview)
            rollingSplitsPage
                .tag(DistanceTilePage.rollingSplits)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 150)
    }

    private var overviewPage: some View {
        metricsPage(
            leading: sideMetric(speed: metrics.averageSpeed, label: "average pace"),
            trailing: sideMetric(speed: metrics.lastKilometerSpeed, label: "pace last km")
        )
    }

    private var rollingSplitsPage: some View {
        metricsPage(
            leading: sideMetric(speed: metrics.recentAverageSpeed, label: "average last 5 km"),
            trailing: sideMetric(speed: metrics.maxSpeed, label: "best pace")
        )
    }

    // MARK: - SubView

    private func metricsPage(leading: some View, trailing: some View) -> some View {
        ZStack {
            heroPace
            HStack(alignment: .bottom) {
                leading
                Spacer()
                trailing
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.bottom, 16)
    }

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

// MARK: - Pace Formatting

/// Shared by the running tiles (outdoor + treadmill). Pace is the inverse of
/// speed, so a stationary runner would show an infinite pace — anything slower
/// than the walking threshold renders as the placeholder instead.
enum PaceFormatter {

    /// Below this speed a pace value is meaningless (standing still / no data).
    private static let minimumSpeed: Double = 0.3 // m/s ≈ 55 min/km

    /// "5:32" for 3.01 m/s; "—" for nil, zero, or implausibly slow input.
    static func text(fromMetersPerSecond speed: Double?) -> String {
        guard let speed, speed >= minimumSpeed else { return "—" }
        let secondsPerKilometer = Int((1_000 / speed).rounded())
        return "\(secondsPerKilometer / 60):\(String(format: "%02d", secondsPerKilometer % 60))"
    }

    /// "5,82 km" for 5820 m; "—" when the source delivers no distance at all
    /// (e.g. treadmill without a Watch).
    static func distanceText(fromMeters meters: Double?) -> String {
        guard let meters else { return "—" }
        return Measurement(value: meters, unit: UnitLength.meters)
            .converted(to: .kilometers)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            ))
    }
}

#Preview("Running tile") {
    RunningTileView(
        metrics: WorkoutMetrics(
            averageHeartRate: 148,
            heartRate: 152,
            activeEnergy: 320,
            distance: 5_820,
            currentSpeed: 3.01,
            averageSpeed: 2.85,
            maxSpeed: 3.7,
            recentAverageSpeed: 2.92,
            lastKilometerSpeed: 3.08
        ),
        currentPage: .constant(.overview)
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Running tile — no data") {
    RunningTileView(
        metrics: WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0),
        currentPage: .constant(.overview)
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
