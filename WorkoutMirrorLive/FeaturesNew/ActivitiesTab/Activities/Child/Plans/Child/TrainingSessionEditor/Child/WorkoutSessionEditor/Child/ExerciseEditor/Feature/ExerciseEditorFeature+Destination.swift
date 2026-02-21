//
//  ExerciseEditorFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture

extension ExerciseEditorFeature {

    @Reducer
    enum Destination {
        /// Searchable list for choosing an exercise type.
        case picker(ExercisePickerFeature)
    }
}
