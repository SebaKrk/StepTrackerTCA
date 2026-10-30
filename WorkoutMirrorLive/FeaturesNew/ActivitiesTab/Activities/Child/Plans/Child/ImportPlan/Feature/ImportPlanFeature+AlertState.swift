//
//  ImportPlanFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == ImportPlanFeature.Action.Alert {

    static let malformed = Self {
        TextState(String(localized: "Couldn't read the plan"))
    } message: {
        TextState(String(localized: "This code doesn't contain a valid training plan."))
    }
}
