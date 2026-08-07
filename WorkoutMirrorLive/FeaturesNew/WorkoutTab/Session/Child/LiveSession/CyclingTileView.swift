//
//  CyclingTileView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import SharedModels
import SwiftUI

/// Carousel pages shared by the distance-activity tiles (cycling, running).
nonisolated enum DistanceTilePage: Hashable, Sendable {

    /// Hero value + session average / best.
    case overview

    /// Hero value + rolling metrics (last 5 km average, last km).
    case rollingSplits
}

/// Live cycling tile — hero km/h with distance in the header and a swipeable
/// pair of stat pages. Dumb view: metrics come in whole, page selection goes
/// out through the binding (state lives in `LiveSessionFeature`).
struct CyclingTileView: View {

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
            leading: sideMetric(speed: metrics.averageSpeed, label: "average speed"),
            trailing: sideMetric(speed: metrics.maxSpeed, label: "maximum speed")
        )
    }

    private var rollingSplitsPage: some View {
        metricsPage(
            leading: sideMetric(speed: metrics.recentAverageSpeed, label: "average last 5 km"),
            trailing: sideMetric(speed: metrics.lastKilometerSpeed, label: "pace last km")
        )
    }

    // MARK: - SubView

    private func metricsPage(leading: some View, trailing: some View) -> some View {
        ZStack {
            heroSpeed
            HStack(alignment: .bottom) {
                leading
                Spacer()
                trailing
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.bottom, 16)
    }

    private var heroSpeed: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(kilometersPerHour(metrics.currentSpeed).formatted(Self.speedFormat))
                .font(.system(size: 54, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: metrics.currentSpeed ?? 0))
                .animation(.snappy(duration: 0.3), value: metrics.currentSpeed)
            Text(verbatim: "km/h")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }

    private func sideMetric(speed: Double?, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(kilometersPerHour(speed).formatted(Self.speedFormat))
                .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: speed ?? 0))
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
            Text(formattedDistance)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: metrics.distance ?? 0))
                .animation(.snappy(duration: 0.3), value: metrics.distance)
        }
    }

    // MARK: - Formatting

    private static let speedFormat: FloatingPointFormatStyle<Double> =
        .number.precision(.fractionLength(1))

    private func kilometersPerHour(_ metersPerSecond: Double?) -> Double {
        Measurement(value: metersPerSecond ?? 0, unit: UnitSpeed.metersPerSecond)
            .converted(to: .kilometersPerHour)
            .value
    }

    private var formattedDistance: String {
        Measurement(value: metrics.distance ?? 0, unit: UnitLength.meters)
            .converted(to: .kilometers)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            ))
    }
}

#Preview("Cycling tile") {
    CyclingTileView(
        metrics: WorkoutMetrics(
            averageHeartRate: 128,
            heartRate: 132,
            activeEnergy: 240,
            distance: 5_820,
            currentSpeed: 6.75,
            averageSpeed: 5.94,
            maxSpeed: 9.06,
            recentAverageSpeed: 6.33,
            lastKilometerSpeed: 6.53
        ),
        currentPage: .constant(.overview)
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Cycling tile — no data") {
    CyclingTileView(
        metrics: WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0),
        currentPage: .constant(.overview)
    )
    .padding(8)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
