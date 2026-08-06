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
            TextState("Discard workout?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.confirmDiscard)) {
                TextState("Discard")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("The workout will be removed from HealthKit and won't be saved.")
        }
    }
}
