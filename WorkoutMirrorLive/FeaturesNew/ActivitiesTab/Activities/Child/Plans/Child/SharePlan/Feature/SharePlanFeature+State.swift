//
//  SharePlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SharedModels

extension SharePlanFeature {

    @ObservableState
    struct State {

        /// The plan being shared.
        var plan: TrainingSession

        /// Result of QR generation; `nil` while it's still being rendered (spinner).
        var qrResult: PlanShareResult?

        init(plan: TrainingSession) {
            self.plan = plan
        }
    }
}
