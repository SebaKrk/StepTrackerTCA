//
//  TrainingNoteKind.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// Which cue the proxy should write for a planned session.
public enum TrainingNoteKind: String, Sendable {

    /// What to prime before the blocks.
    case warmUp

    /// What to release after the blocks.
    case coolDown
}
