//
//  ScanPlanFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == ScanPlanFeature.Action.Alert {

    /// Consent gate before a plan photo leaves the phone — names who receives it.
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
        TextState("The photo of your plan goes through our server to Anthropic, which reads it and returns the plan. We keep no copy, and Anthropic gets no name or account with it.")
    }
}
