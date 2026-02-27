//
//  WorkoutPreviewFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 22/02/2026.
//

import ComposableArchitecture

extension WorkoutPreviewFeature {

    @Reducer
    enum Destination {
        /// Edit the parsed training session before saving.
        case editor(TrainingSessionEditorFeature)
    }
}
