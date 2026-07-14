//
//  AddMeasurementFeature+AlertState.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/02/2025.
//

import ComposableArchitecture

/// Alert state for `AddMeasurementFeature`
extension AlertState where Action == AddMeasurementFeature.Action.Alert {
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
