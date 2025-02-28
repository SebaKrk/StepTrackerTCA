//
//  AddMetricDataFeature+AlertState.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/12/2024.
//

import ComposableArchitecture

/// Alert state for `AddMetricDataFeature`
extension AlertState where Action == AddMetricDataFeature.Action.Alert {
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
