//
//  PublishPlanFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == PublishPlanFeature.Action.Alert {

    static func publishFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Publish the Plan"))
        } message: {
            TextState(message)
        }
    }
}
