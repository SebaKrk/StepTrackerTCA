//
//  OpenLadderPlan.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import Foundation

/// A rep ladder with no last rung: "1-2-3-4-5-6-…" goes on for as long as the clock runs.
public struct OpenLadderPlan: Codable, Equatable, Sendable {

    /// Reps of every movement in the first round.
    public let firstRung: Int

    /// How much each round adds to the one before it.
    public let step: Int

    public init(firstRung: Int, step: Int) {
        self.firstRung = firstRung
        self.step = step
    }

    /// The ladder a board writes before its ellipsis; nil when there is nothing to continue.
    public init?(writtenRungs: [Int]) {
        guard let first = writtenRungs.first, first > 0 else { return nil }
        self.firstRung = first
        self.step = writtenRungs.count > 1 ? writtenRungs[1] - first : 1
    }

    /// Reps of every movement in a round, counted from zero; never below zero.
    public func rung(at round: Int) -> Int {
        max(0, firstRung + step * max(0, round))
    }

    /// The first `count` rungs, enough to score an attempt that reached that many rounds.
    public func rungs(count: Int) -> [Int] {
        (0..<max(0, count)).map(rung(at:))
    }

    /// The ladder as a board writes it: "1-2-3-4-5-6…".
    public var summary: String {
        rungs(count: 6).map(String.init).joined(separator: "-") + "…"
    }
}
