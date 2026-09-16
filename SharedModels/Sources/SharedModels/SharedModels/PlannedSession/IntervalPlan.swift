//
//  IntervalPlan.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 06/09/2026.
//

import Foundation

/// Work/rest round timer of one planned session (e.g. boxing 30×(30s/30s)) —
/// a session-level timer configuration, not an exercise score (unlike Tabata).
public struct IntervalPlan: Codable, Equatable, Sendable {

    /// Work segment length in seconds.
    public let workSeconds: Int

    /// Rest segment length in seconds; the last round has no trailing rest.
    public let restSeconds: Int

    /// Number of work rounds.
    public let rounds: Int

    public init(workSeconds: Int, restSeconds: Int, rounds: Int) {
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.rounds = rounds
    }
}
