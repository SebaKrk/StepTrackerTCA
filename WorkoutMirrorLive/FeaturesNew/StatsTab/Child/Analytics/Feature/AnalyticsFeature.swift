//
//  AnalyticsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Feature responsible for the Analytics tab content within the Stats screen.
///
/// `AnalyticsFeature` manages historical workout trends and performance analysis.
/// It acts as a parent reducer composing child features for individual analytics sections
/// (e.g., Workout Volume, Training Readiness Trend).
///
/// This feature is lazily initialized — only created when the user first switches
/// the Stats picker to the `.analytics` context. Child features are initialized
/// on `viewDidAppear` to defer HealthKit queries until the view is visible.
///
/// ## Architecture
/// - **Parent of:** `WorkoutVolumeFeature`, `ReadinessTrendFeature`, `WeightTrendFeature`
/// - **Owned by:** `StatsFeature` (optional child, lazy init)
/// - **Navigation:** No destinations yet (future: drill-downs for sections)
@Reducer
struct AnalyticsFeature {

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Internal Action

            case .internal(.initializeChildren):
                state.workoutVolume = WorkoutVolumeFeature.State()
                state.readinessTrend = ReadinessTrendFeature.State()
                state.weightTrend = WeightTrendFeature.State()
                state.healthMetricsTrend = HealthMetricsTrendFeature.State()
                return .none

                // MARK: - View Action

            case .view(.viewDidAppear):
                guard state.workoutVolume == nil else {
                    return .none
                }
                return .send(.internal(.initializeChildren))

            case .view(.refresh):
                var effects: [Effect<Action>] = []
                if state.workoutVolume != nil {
                    effects.append(.send(.workoutVolume(.view(.refresh))))
                }
                if state.readinessTrend != nil {
                    effects.append(.send(.readinessTrend(.view(.refresh))))
                }
                if state.weightTrend != nil {
                    effects.append(.send(.weightTrend(.view(.refresh))))
                }
                if state.healthMetricsTrend != nil {
                    effects.append(.send(.healthMetricsTrend(.view(.refresh))))
                }
                return .merge(effects)

                // MARK: - Child

            case .workoutVolume:
                return .none

            case .readinessTrend:
                return .none

            case .weightTrend:
                return .none

            case .healthMetricsTrend:
                return .none
            }
        }
        .ifLet(\.workoutVolume, action: \.workoutVolume) {
            WorkoutVolumeFeature()
        }
        .ifLet(\.readinessTrend, action: \.readinessTrend) {
            ReadinessTrendFeature()
        }
        .ifLet(\.weightTrend, action: \.weightTrend) {
            WeightTrendFeature()
        }
        .ifLet(\.healthMetricsTrend, action: \.healthMetricsTrend) {
            HealthMetricsTrendFeature()
        }
    }
}
