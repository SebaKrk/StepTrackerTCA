//
//  PersonalActivityFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

// MARK: - Delete confirmation

extension AlertState where Action == PersonalActivityFeature.Action.DeleteAlert {
    static var deleteWorkout: Self {
        Self {
            TextState("Delete workout?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.confirmDelete)) {
                TextState("Delete")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("The workout will be permanently deleted from HealthKit.")
        }
    }
}

// MARK: - Delete error

extension AlertState where Action == Never {
    static var cannotDelete: Self {
        Self {
            TextState("Can't delete workout")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState("HealthKit only allows deleting workouts recorded by this app.")
        }
    }
}
