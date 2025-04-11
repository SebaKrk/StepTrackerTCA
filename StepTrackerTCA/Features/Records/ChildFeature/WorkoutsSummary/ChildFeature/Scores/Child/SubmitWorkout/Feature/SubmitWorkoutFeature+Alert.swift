//
//  SubmitWorkoutFeature+Alert.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import ComposableArchitecture

/// Alert state for `SubmitWorkoutFeature`
extension AlertState where Action == SubmitWorkoutFeature.Action.Alert {
    static func infoAlert(with message: String) -> Self {
        Self {
            TextState("Warning")
        } actions: {
            ButtonState(role: .cancel,
                        action: .send(.showMessage)) {
                TextState("OK")
            }
        } message: {
            TextState(message)
        }
    }
    
}
