//
//  SetWeightGoalFeature+AlertState.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/02/2025.
//

import ComposableArchitecture

/// Alert state for `SetWeightGoalFeature`
extension AlertState where Action == SetWeightGoalFeature.Action.Alert {
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
