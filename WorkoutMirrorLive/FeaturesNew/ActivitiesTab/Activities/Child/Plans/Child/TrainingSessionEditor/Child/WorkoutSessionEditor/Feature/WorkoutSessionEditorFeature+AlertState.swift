//
//  WorkoutSessionEditorFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 25/02/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == WorkoutSessionEditorFeature.Action.Alert {

    static func confirmDelete(name: String) -> Self {
        Self {
            TextState("Delete Workout")
        } actions: {
            ButtonState(role: .destructive, action: .deleteConfirmed) {
                TextState("Delete")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("\"\(name)\" and all its exercises will be removed.")
        }
    }
}
