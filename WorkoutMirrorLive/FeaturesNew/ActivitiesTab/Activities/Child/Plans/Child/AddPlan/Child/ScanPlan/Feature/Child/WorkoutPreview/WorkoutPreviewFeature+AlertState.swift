//
//  WorkoutPreviewFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == WorkoutPreviewFeature.Action.Alert {

    /// Consent gate before a plan's text leaves the phone — names who receives it.
    static let confirmAIProcessing = Self {
        TextState("Send the plan to an AI service?")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Not now")
        }
        ButtonState(action: .aiProcessingAllowed) {
            TextState("Allow")
        }
    } message: {
        TextState("The names of the blocks and exercises go through our server to Anthropic, which writes the warm-up and cool-down. We keep no copy, and Anthropic gets no name or account with them.")
    }

    /// Generation failed; the plan stays as scanned and the button is back.
    static func notesGenerationFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't generate the notes"))
        } message: {
            TextState(message)
        }
    }
}
