//
//  PRResolver.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation
import IssueReporting

/// Current PRs of one movement. For movements without Rx/scaled support only
/// `best` is populated; for benchmarks `best` mirrors `bestRx ?? bestScaled`.
public struct PRSummary: Equatable, Sendable {
    public let best: PREntry?
    public let bestRx: PREntry?
    public let bestScaled: PREntry?

    public init(best: PREntry?, bestRx: PREntry?, bestScaled: PREntry?) {
        self.best = best
        self.bestRx = bestRx
        self.bestScaled = bestScaled
    }
}

/// Pure derivation of current PRs from entry history (FR-007).
/// No state, no dependencies, no denormalized "best" anywhere — deleting an
/// entry rolls the PR back by construction.
public enum PRResolver {

    /// Rx and scaled are separate rankings — a better scaled result never
    /// beats an Rx one. Entries with `isRx == nil` count as scaled.
    public static func summary(for movement: PRMovement, entries: [PREntry]) -> PRSummary {
        let movementEntries = entries.filter { $0.movementId == movement.id }
        // D4 (plan testing-pr-correctness-all-types): an entry whose score type
        // disagrees with the movement's catalog type must never beat a matching
        // one. The partition is history-wide, not per-Rx/scaled-bucket: a single
        // matching entry evicts mismatched ones from every bucket (a bogus Rx
        // never holds the Rx slot); the fallback to mismatched entries applies
        // only when NO matching entry exists, and every exclusion reports below.
        let matching = movementEntries.filter { $0.score.scoreType == movement.scoreType }
        let mismatched = movementEntries.filter { $0.score.scoreType != movement.scoreType }
        for entry in mismatched {
            reportIssue("PRResolver: entry \(entry.id) scores \(entry.score.scoreType) on movement \(movement.id) (\(movement.scoreType)) — mismatched type")
        }
        let ranked = matching.isEmpty ? mismatched : matching
        guard movement.supportsRxScaled else {
            return PRSummary(best: best(of: ranked), bestRx: nil, bestScaled: nil)
        }
        let bestRx = best(of: ranked.filter { $0.isRx == true })
        let bestScaled = best(of: ranked.filter { $0.isRx != true })
        return PRSummary(best: bestRx ?? bestScaled, bestRx: bestRx, bestScaled: bestScaled)
    }

    /// Better score wins; score tie → later `date`; date tie → later `createdAt`.
    public static func isBetter(_ lhs: PREntry, than rhs: PREntry) -> Bool {
        switch compareScores(lhs.score, rhs.score) {
        case .orderedDescending: return true
        case .orderedAscending:  return false
        case .orderedSame:
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.createdAt > rhs.createdAt
        }
    }

    /// Movements that have at least one entry (category completion counters).
    public static func completedMovementIds(entries: [PREntry]) -> Set<String> {
        Set(entries.map(\.movementId))
    }

    /// Day of the most recent entry (category "last PR" label).
    public static func latestEntryDate(entries: [PREntry]) -> Date? {
        entries.map(\.date).max()
    }

    // MARK: - Private

    private static func best(of entries: [PREntry]) -> PREntry? {
        entries.reduce(nil) { current, candidate in
            guard let current else { return candidate }
            return isBetter(candidate, than: current) ? candidate : current
        }
    }

    /// Direction per score type: weight/reps higher wins, time lower wins,
    /// AMRAP compares lexicographically (rounds, then extra reps).
    /// Mismatched pairs are excluded from ranking upstream (D4 partition in
    /// `summary`); the orderedSame fallback only orders a mismatched-only
    /// history, where the date/createdAt tie-break is good enough.
    private static func compareScores(_ lhs: PRScoreValue, _ rhs: PRScoreValue) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (.weight(left), .weight(right)):
            return compare(left, right)
        case let (.time(left), .time(right)):
            return compare(right, left)
        case let (.reps(left), .reps(right)):
            return compare(left, right)
        case let (.amrap(leftRounds, leftReps), .amrap(rightRounds, rightReps)):
            let rounds = compare(leftRounds, rightRounds)
            return rounds == .orderedSame ? compare(leftReps, rightReps) : rounds
        default:
            return .orderedSame
        }
    }

    private static func compare<Value: Comparable>(_ lhs: Value, _ rhs: Value) -> ComparisonResult {
        if lhs > rhs { return .orderedDescending }
        if lhs < rhs { return .orderedAscending }
        return .orderedSame
    }
}
