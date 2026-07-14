//
//  AddPlanFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture

extension AddPlanFeature {

    @Reducer
    enum Destination {

        /// Scan a workout plan from a photo using OCR.
        case scanPlan(ScanPlanFeature)

        /// Manually create or edit a workout plan.
        case editor(TrainingSessionEditorFeature)
    }

}
