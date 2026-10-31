//
//  WorkoutPreviewFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == WorkoutPreviewFeature.Action.Alert {

    /// Generation failed; the plan stays as scanned and the button is back.
    static func notesGenerationFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't generate the notes"))
        } message: {
            TextState(message)
        }
    }
}
