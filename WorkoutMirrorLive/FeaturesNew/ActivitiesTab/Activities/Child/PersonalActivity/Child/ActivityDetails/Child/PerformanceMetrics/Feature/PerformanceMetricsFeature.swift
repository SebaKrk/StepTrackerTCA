//
//  PerformanceMetricsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels

/// Performance-metrics domain of the Activity Details screen: hrTSS, intensity
/// factor, HR recovery and recovery demand cards (plus METs, displayed by the
/// parent's energy section).
///
/// Emits `delegate(.didFinishLoading)` for the parent's recap-map gate and
/// `delegate(.openMetricDetails)` when a card title is tapped — navigation
/// stays with the parent, which owns the destinations.
@Reducer
struct PerformanceMetricsFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient

    // MARK: - State

    @ObservableState
    struct State {

        /// The workout being displayed.
        var workout: HKWorkout

        /// User's maximum heart rate — input for TRIMP/hrTSS/IF calculations.
        var maxHeartRate: Double

        /// Metabolic Equivalent of Task - workout intensity vs rest.
        var mets: Double?

        /// Training Impulse - training load based on time in HR zones.
        var trimp: Double?

        /// Heart Rate Training Stress Score - normalized training stress.
        var hrTSS: Double?

        /// Heart rate recovery - BPM drop 1 minute after workout.
        var hrRecovery: Int?

        /// Intensity Factor - workout effort relative to lactate threshold.
        var intensityFactor: Double?

        /// Recovery Demand - estimated recovery time based on training load and metrics.
        var recoveryDemand: RecoveryDemand?

        // MARK: - Level classifications

        /// hrTSS stress level classification.
        var hrTSSLevel: HRTSSLevel? {
            guard let hrTSS else { return nil }
            return HRTSSLevel.from(value: hrTSS)
        }

        /// HR Recovery fitness level classification.
        var hrRecoveryLevel: HRRecoveryLevel? {
            guard let hrRecovery else { return nil }
            return HRRecoveryLevel.from(value: hrRecovery)
        }

        /// Intensity Factor level classification.
        var intensityFactorLevel: IntensityFactorLevel? {
            guard let intensityFactor else { return nil }
            return IntensityFactorLevel.from(value: intensityFactor)
        }

        /// Recovery Demand level classification.
        var recoveryDemandLevel: RecoveryDemandLevel? {
            recoveryDemand?.level
        }

        // MARK: - Formatters

        /// METs formatted for display — consumed by the parent's energy section too.
        var formattedMETs: String {
            guard let mets else { return "—" }
            return String(format: "%.1f", mets)
        }

        var formattedHRTSS: String {
            guard let hrTSS else { return "—" }
            return "\(Int(hrTSS))"
        }

        var formattedHRRecovery: String {
            guard let hrRecovery else { return "—" }
            return "\(hrRecovery)"
        }

        var formattedIntensityFactor: String {
            guard let intensityFactor else { return "—" }
            return String(format: "%.2f", intensityFactor)
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// Command from the parent — starts the metrics load.
        case load

        case `internal`(Internal)

        enum Internal {

            /// All performance metrics loaded (each `nil` on its own failure).
            case metricsLoaded(mets: Double?, trimp: Double?, hrTSS: Double?, hrRecovery: Int?, intensityFactor: Double?, recoveryDemand: RecoveryDemand?)
        }

        case view(View)

        enum View {

            /// Card title tapped — the parent opens the metric-details destination.
            case metricTapped(MetricTypeDetails)
        }

        case delegate(Delegate)

        @CasePathable
        enum Delegate {

            /// The metrics load settled (successfully or not).
            case didFinishLoading

            /// User wants the details screen for the tapped metric.
            case openMetricDetails(MetricTypeDetails)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .load:
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate

                return .run { [activityClient] send in
                    async let metsTask = activityClient.fetchMETs(workout)
                    async let trimpTask = activityClient.fetchTRIMP(workout, maxHeartRate)
                    async let hrTSSTask = activityClient.fetchHRTSS(workout, maxHeartRate)
                    async let hrRecoveryTask = activityClient.fetchHRRecovery(workout)
                    async let intensityFactorTask = activityClient.fetchIntensityFactor(workout, maxHeartRate)
                    async let recoveryDemandTask = activityClient.fetchRecoveryDemand(workout, maxHeartRate)

                    let mets = try? await metsTask
                    let trimp = try? await trimpTask
                    let hrTSS = try? await hrTSSTask
                    let hrRecovery = try? await hrRecoveryTask
                    let intensityFactor = try? await intensityFactorTask
                    let recoveryDemand = try? await recoveryDemandTask

                    await send(.internal(.metricsLoaded(
                        mets: mets,
                        trimp: trimp,
                        hrTSS: hrTSS,
                        hrRecovery: hrRecovery,
                        intensityFactor: intensityFactor,
                        recoveryDemand: recoveryDemand
                    )))
                }

            case let .internal(.metricsLoaded(mets, trimp, hrTSS, hrRecovery, intensityFactor, recoveryDemand)):
                state.mets = mets
                state.trimp = trimp
                state.hrTSS = hrTSS
                state.hrRecovery = hrRecovery
                state.intensityFactor = intensityFactor
                state.recoveryDemand = recoveryDemand
                return .send(.delegate(.didFinishLoading))

            case let .view(.metricTapped(metric)):
                return .send(.delegate(.openMetricDetails(metric)))

            case .delegate:
                return .none
            }
        }
    }
}
