//
//  ExerciseDetailFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == ExerciseDetailFeature.Action.Alert {

    /// Consent gate for the unrecognized-names report — says exactly what leaves
    /// the device before the share sheet appears.
    static let confirmSendReport = AlertState {
        TextState("Send to the developer?")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
        ButtonState(action: .sendReportConfirmed) {
            TextState("Send")
        }
    } message: {
        TextState("You'll share a .txt file with the unrecognized exercise names and their occurrence counts — no workout data included.")
    }
}
