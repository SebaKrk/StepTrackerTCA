//
//  TrainingNotes.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 18/11/2026.
//

import Foundation

/// The cues a plan can carry, as the proxy returns them.
///
/// Both cues travel together so a plan missing warm-up and cool-down needs one
/// round-trip. A length is filled only where the model chose it; one the caller
/// set is already theirs and comes back `nil`.
public struct TrainingNotes: Equatable, Sendable {

    /// What to prime before the blocks.
    public let warmUp: String?

    /// How long the warm-up takes.
    public let warmUpMinutes: Int?

    /// What to release after the blocks.
    public let coolDown: String?

    /// How long the cool-down takes.
    public let coolDownMinutes: Int?

    public init(warmUp: String?, warmUpMinutes: Int?, coolDown: String?, coolDownMinutes: Int?) {
        self.warmUp = warmUp
        self.warmUpMinutes = warmUpMinutes
        self.coolDown = coolDown
        self.coolDownMinutes = coolDownMinutes
    }
}
