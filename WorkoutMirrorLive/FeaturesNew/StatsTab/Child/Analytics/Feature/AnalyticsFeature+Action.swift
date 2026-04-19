//
//  AnalyticsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture

/// Action definitions for `AnalyticsFeature`.
///
/// Actions are split into:
/// - **Internal** — business logic actions not triggered directly by the view
/// - **View** — actions mapped from user interactions via `@ViewAction`
/// - **Child** — forwarded actions from child features
extension AnalyticsFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        case `internal`(Internal)

        enum Internal {

            /// Initializes all child features after the analytics view appears.
            /// Creates `WorkoutVolumeFeature.State` and `ReadinessTrendFeature.State`.
            case initializeChildren
        }

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Triggered when the analytics view appears on screen.
            /// Initializes children if not yet created (first appearance only).
            case viewDidAppear

            /// Triggered by pull-to-refresh gesture.
            /// Cascades refresh to all active child features.
            case refresh
        }

        // MARK: - Child Actions

        /// Forwards actions to the `WorkoutVolumeFeature`.
        /// Handles weekly workout volume data and chart interactions.
        case workoutVolume(WorkoutVolumeFeature.Action)

        /// Forwards actions to the `ReadinessTrendFeature`.
        /// Handles training readiness history and trend visualization.
        case readinessTrend(ReadinessTrendFeature.Action)

        /// Forwards actions to the `WeightTrendFeature`.
        /// Handles weight history and trend line chart.
        case weightTrend(WeightTrendFeature.Action)

        /// Forwards actions to the `HealthMetricsTrendFeature`.
        /// Handles RHR, HRV, Sleep and Activity metric trends.
        case healthMetricsTrend(HealthMetricsTrendFeature.Action)
    }
}
