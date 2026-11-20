//
//  ReadinessDelivery.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation
import SharedModels

/// What the paired iPhone sends about training readiness.
enum ReadinessDelivery: Equatable, Sendable {

    /// A calculated score with its components.
    case snapshot(ReadinessSnapshot)

    /// Readiness needs Pro; nothing calculated is sent.
    case locked
}
