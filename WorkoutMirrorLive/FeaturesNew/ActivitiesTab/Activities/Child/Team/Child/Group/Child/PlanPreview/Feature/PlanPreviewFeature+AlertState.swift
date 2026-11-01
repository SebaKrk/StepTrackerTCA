//
//  PlanPreviewFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == PlanPreviewFeature.Action.Alert {

    static func downloadFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Download the Plan"))
        } message: {
            TextState(message)
        }
    }
}
