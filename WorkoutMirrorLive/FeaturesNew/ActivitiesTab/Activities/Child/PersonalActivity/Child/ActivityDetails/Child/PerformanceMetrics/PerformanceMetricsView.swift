//
//  PerformanceMetricsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// 2×2 grid of tappable performance-metric cards (hrTSS, Intensity, HR
/// Recovery, Recovery Demand). Card taps route to the parent via delegate.
@ViewAction(for: PerformanceMetricsFeature.self)
struct PerformanceMetricsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PerformanceMetricsFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
                hrTSSCard
                intensityCard
            }
            LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
                hrRecoveryCard
                recoveryDemandCard
            }
        }
    }

    // MARK: - Cards

    private var hrTSSCard: some View {
        TappableMetricCard(
            title: hrTSSTitle,
            value: store.formattedHRTSS,
            unit: "",
            label: store.hrTSSLevel?.recoveryEstimate ?? "",
            labelColor: store.hrTSSLevel?.color ?? .gray,
            icon: "figure.run"
        ) {
            if let hrTSS = store.hrTSS, let level = store.hrTSSLevel {
                send(.metricTapped(.hrTSS(value: hrTSS, level: level)))
            }
        }
    }

    private var intensityCard: some View {
        TappableMetricCard(
            title: intensityTitle,
            value: store.formattedIntensityFactor,
            unit: "",
            label: store.intensityFactorLevel?.title ?? "",
            labelColor: store.intensityFactorLevel?.color ?? .gray,
            icon: "gauge.with.needle"
        ) {
            if let intensity = store.intensityFactor, let level = store.intensityFactorLevel {
                send(.metricTapped(.intensity(value: intensity, level: level)))
            }
        }
    }

    private var hrRecoveryCard: some View {
        TappableMetricCard(
            title: hrRecoveryTitle,
            value: store.formattedHRRecovery,
            unit: "bpm",
            label: store.hrRecoveryLevel?.title ?? "",
            labelColor: store.hrRecoveryLevel?.color ?? .gray,
            icon: "arrow.down.heart.fill"
        ) {
            if let hrRecovery = store.hrRecovery, let level = store.hrRecoveryLevel {
                send(.metricTapped(.hrRecovery(value: hrRecovery, level: level)))
            }
        }
    }

    private var recoveryDemandCard: some View {
        TappableMetricCard(
            title: recoveryDemandTitle,
            value: store.recoveryDemandLevel?.valueString ?? "—",
            unit: store.recoveryDemandLevel?.unitString ?? "",
            label: store.recoveryDemandLevel?.title ?? "",
            labelColor: store.recoveryDemandLevel?.color ?? .gray,
            icon: "bed.double.fill"
        ) {
            if let recoveryDemand = store.recoveryDemand, let level = store.recoveryDemandLevel {
                send(.metricTapped(.recoveryDemand(value: recoveryDemand, level: level)))
            }
        }
    }

    // MARK: - Implementation

    private var hrTSSTitle: String {
        String(localized: "hrTSS", bundle: .main)
    }

    private var intensityTitle: String {
        String(localized: "Intensity", bundle: .main)
    }

    private var hrRecoveryTitle: String {
        String(localized: "HR Recovery", bundle: .main)
    }

    private var recoveryDemandTitle: String {
        String(localized: "Recovery Demand", bundle: .main)
    }
}
