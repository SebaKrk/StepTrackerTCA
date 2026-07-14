//
//  TrainingSessionEditorFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == TrainingSessionEditorFeature.Action.Alert {

    static let removeWarmUp = Self {
        TextState("Remove Warmup?")
    } actions: {
        ButtonState(role: .destructive, action: .warmUpRemoveConfirmed) {
            TextState("Remove")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Your warmup notes will be lost.")
    }

    static let removeCoolDown = Self {
        TextState("Remove Cooldown?")
    } actions: {
        ButtonState(role: .destructive, action: .coolDownRemoveConfirmed) {
            TextState("Remove")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Your cooldown notes will be lost.")
    }

    static func confirmDelete(title: String) -> Self {
        Self {
            TextState("Delete Training Session?")
        } actions: {
            ButtonState(role: .destructive, action: .deleteConfirmed) {
                TextState("Delete")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("\"\(title)\" and all its workouts will be permanently removed.")
        }
    }

    static func generationFailed(_ message: String) -> Self {
        Self {
            TextState("Generation Failed")
        } actions: {
            ButtonState(action: .generationErrorDismissed) {
                TextState("OK")
            }
        } message: {
            TextState(message)
        }
    }
}
