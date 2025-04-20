//
//  WorkoutSubmissionFeature+Alert.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import ComposableArchitecture

/// Alert state for `WorkoutSubmissionFeature`
extension AlertState where Action == WorkoutSubmissionFeature.Action.Alert {
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
