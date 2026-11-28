//
//  TrainingSessionEditorFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture

extension TrainingSessionEditorFeature {

    @Reducer
    enum Destination {
        /// Create or edit a single WOD within the training session.
        case workoutEditor(WorkoutSessionEditorFeature)

        /// Create or edit the warm-up block (a Tabata, a timed run…).
        case warmUpBlockEditor(WorkoutSessionEditorFeature)

        /// Create or edit the cool-down block.
        case coolDownBlockEditor(WorkoutSessionEditorFeature)
    }
}
