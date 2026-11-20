//
//  PREntryEditorFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == PREntryEditorFeature.Action.Alert {

    /// A failed save keeps the sheet open, so the user can retry.
    static let saveFailed = Self {
        TextState("Couldn't Save Result")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Your result was not saved. Please try again.")
    }
}
