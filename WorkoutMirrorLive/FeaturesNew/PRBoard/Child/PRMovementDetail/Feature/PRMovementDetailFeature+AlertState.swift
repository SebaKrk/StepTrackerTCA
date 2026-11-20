//
//  PRMovementDetailFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == PRMovementDetailFeature.Action.Alert {

    /// A failed delete must be distinguishable from success.
    static let deleteFailed = Self {
        TextState("Couldn't Delete Entry")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("The entry was not deleted. Please try again.")
    }
}
