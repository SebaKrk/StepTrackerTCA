//
//  SummaryFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == SummaryFeature.Action.DiscardAlert {
    static var discardWorkout: Self {
        Self {
            TextState("Odrzuć trening?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.confirmDiscard)) {
                TextState("Odrzuć")
            }
            ButtonState(role: .cancel) {
                TextState("Anuluj")
            }
        } message: {
            TextState("Trening zostanie usunięty z HealthKit i nie zostanie zapisany.")
        }
    }
}
