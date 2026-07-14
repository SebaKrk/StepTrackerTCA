//
//  WorkoutSessionEditorFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture

extension WorkoutSessionEditorFeature {

    @Reducer
    enum Destination {
        /// Create or edit a single exercise within the WOD.
        case exerciseEditor(ExerciseEditorFeature)
    }
}
