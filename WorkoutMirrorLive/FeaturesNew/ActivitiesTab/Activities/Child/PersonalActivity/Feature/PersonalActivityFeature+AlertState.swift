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
            TextState("Usuń trening?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.confirmDelete)) {
                TextState("Usuń")
            }
            ButtonState(role: .cancel) {
                TextState("Anuluj")
            }
        } message: {
            TextState("Trening zostanie trwale usunięty z HealthKit.")
        }
    }
}

// MARK: - Delete error

extension AlertState where Action == Never {
    static var cannotDelete: Self {
        Self {
            TextState("Nie można usunąć treningu")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState("HealthKit pozwala usuwać tylko treningi zarejestrowane przez tę aplikację.")
        }
    }
}
