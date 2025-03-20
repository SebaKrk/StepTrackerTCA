//
//  Alert.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/03/2025.
//

import ComposableArchitecture

/// Alert state for `SetEditGoalFeature`
extension AlertState where Action == SetEditGoalFeature.Action.Alert {
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
