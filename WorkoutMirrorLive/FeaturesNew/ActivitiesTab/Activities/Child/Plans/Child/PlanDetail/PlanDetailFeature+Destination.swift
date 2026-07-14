//
//  PlanDetailFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture

extension PlanDetailFeature {

    @Reducer
    enum Destination {

        /// Edit the training session.
        case editor(TrainingSessionEditorFeature)

        /// Browse workout history for this plan.
        case history(WorkoutPlanScoreListFeature)

        /// Share this plan as a QR code.
        case share(SharePlanFeature)
    }
}
