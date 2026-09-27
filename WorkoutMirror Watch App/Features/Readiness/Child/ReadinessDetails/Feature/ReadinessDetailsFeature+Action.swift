//
//  ReadinessDetailsFeature+Action.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `ReadinessDetailsFeature` action.
extension ReadinessDetailsFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - View Actions

        case view(ViewAction)

        @CasePathable
        enum ViewAction {

            /// Called when the user taps a metric row to reveal or hide its explanation.
            case metricTapped(HealthMetricType)

        }

    }

}
