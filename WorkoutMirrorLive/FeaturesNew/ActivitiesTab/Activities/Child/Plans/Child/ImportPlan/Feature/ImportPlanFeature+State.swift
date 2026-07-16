//
//  ImportPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension ImportPlanFeature {

    @ObservableState
    struct State {

        /// Tint color shared across the app (readiness level) — matches PlanDetail.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// Bumped on each failed scan to force the scanner view to remount (and
        /// restart its one-shot camera session). Used as the scanner's `.id`.
        var scanAttempt: Int = 0

        /// Decoded plan awaiting confirmation. Non-nil switches the view from the
        /// scanner to the read-only preview.
        var scannedPlan: TrainingSession?

        /// Shown when a scanned code can't be decoded into a plan.
        @Presents var alert: AlertState<Action.Alert>?

        init() {}
    }
}
