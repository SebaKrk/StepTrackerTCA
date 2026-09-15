//
//  PRResolverTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation
import Testing
@testable import SharedModels

/// FR-007 / PRD Business Logic Changes: current PR derived purely from entry
/// history — direction per score type, lexicographic AMRAP, separate Rx/scaled
/// rankings, ties resolved by newer date. Same-day ties fall back to the newer
/// save timestamp — product decision D1 (plan testing-pr-correctness-all-types,
/// 2026-09-02), not a PRD rule. Oracle decisions D1–D4 live in that plan.
@Suite("PRResolver current PR derivation")
struct PRResolverTests {

    // Fixtures never use `.now` (lessons.md) — whole-second epoch anchors.
    private static let day1 = Date(timeIntervalSince1970: 1_700_000_000)
    private static let day2 = Date(timeIntervalSince1970: 1_700_086_400)
    private static let day3 = Date(timeIntervalSince1970: 1_700_172_800)

    private static let backSquat = PRCatalog.movement(id: "back-squat")!
    private static let fran = PRCatalog.movement(id: "fran")!
    private static let pullUp = PRCatalog.movement(id: "pull-up")!
    private static let cindy = PRCatalog.movement(id: "cindy")!
    private static let row500 = PRCatalog.movement(id: "row-500m")!

    private static func entry(
        movement: PRMovement = backSquat,
        date: Date = day1,
        createdAt: Date? = nil,
        score: PRScoreValue,
        isRx: Bool? = nil
    ) -> PREntry {
        PREntry(
            id: UUID(),
            movementId: movement.id,
            date: date,
            createdAt: createdAt ?? date,
            score: score,
            isRx: isRx
        )
    }

    // MARK: - Directions per score type

    @Test("Weight: higher kilograms win")
    func weightHigherWins() {
        let lighter = Self.entry(date: Self.day2, score: .weight(kilograms: 140))
        let heavier = Self.entry(date: Self.day1, score: .weight(kilograms: 150))
        let summary = PRResolver.summary(for: Self.backSquat, entries: [lighter, heavier])
        #expect(summary.best == heavier)
    }

    @Test("Time: lower seconds win")
    func timeLowerWins() {
        let slower = Self.entry(movement: Self.row500, date: Self.day2, score: .time(seconds: 95))
        let faster = Self.entry(movement: Self.row500, date: Self.day1, score: .time(seconds: 89))
        let summary = PRResolver.summary(for: Self.row500, entries: [slower, faster])
        #expect(summary.best == faster)
    }

    @Test("Reps: higher count wins")
    func repsHigherWins() {
        let fewer = Self.entry(movement: Self.pullUp, score: .reps(count: 18))
        let more = Self.entry(movement: Self.pullUp, date: Self.day2, score: .reps(count: 21))
        let summary = PRResolver.summary(for: Self.pullUp, entries: [more, fewer])
        #expect(summary.best == more)
    }

    @Test("AMRAP compares lexicographically: 6+0 beats 5+10")
    func amrapLexicographic() {
        let fiveTen = Self.entry(movement: Self.cindy, score: .amrap(rounds: 5, extraReps: 10), isRx: true)
        let sixZero = Self.entry(movement: Self.cindy, date: Self.day2, score: .amrap(rounds: 6, extraReps: 0), isRx: true)
        let summary = PRResolver.summary(for: Self.cindy, entries: [fiveTen, sixZero])
        #expect(summary.bestRx == sixZero)
    }

    @Test("AMRAP: equal rounds fall back to extra reps")
    func amrapExtraRepsBreakRounds() {
        let fewerReps = Self.entry(movement: Self.cindy, score: .amrap(rounds: 6, extraReps: 3), isRx: true)
        let moreReps = Self.entry(movement: Self.cindy, date: Self.day2, score: .amrap(rounds: 6, extraReps: 7), isRx: true)
        let summary = PRResolver.summary(for: Self.cindy, entries: [fewerReps, moreReps])
        #expect(summary.bestRx == moreReps)
    }

    // MARK: - Ties

    @Test("Equal score: newer date wins")
    func tieNewerDateWins() {
        let older = Self.entry(date: Self.day1, score: .weight(kilograms: 150))
        let newer = Self.entry(date: Self.day3, score: .weight(kilograms: 150))
        let summary = PRResolver.summary(for: Self.backSquat, entries: [older, newer])
        #expect(summary.best == newer)
    }

    @Test("Same-day duplicate with equal score: newer createdAt wins")
    func tieSameDayNewerCreatedAtWins() {
        let morning = Self.entry(date: Self.day1, createdAt: Self.day1, score: .weight(kilograms: 150))
        let evening = Self.entry(
            date: Self.day1,
            createdAt: Self.day1.addingTimeInterval(6 * 3600),
            score: .weight(kilograms: 150)
        )
        let summary = PRResolver.summary(for: Self.backSquat, entries: [evening, morning])
        #expect(summary.best == evening)
    }

    // MARK: - Rx / scaled split

    @Test("Better scaled time never beats the Rx PR (US-02: Fran 8:10 Rx vs 6:30 scaled)")
    func scaledNeverBeatsRx() {
        let scaledFaster = Self.entry(movement: Self.fran, date: Self.day1, score: .time(seconds: 390), isRx: false)
        let rxSlower = Self.entry(movement: Self.fran, date: Self.day2, score: .time(seconds: 490), isRx: true)
        let summary = PRResolver.summary(for: Self.fran, entries: [scaledFaster, rxSlower])
        #expect(summary.bestRx == rxSlower)
        #expect(summary.bestScaled == scaledFaster)
        #expect(summary.best == rxSlower)
    }

    @Test("Benchmark with only scaled entries: best falls back to scaled")
    func benchmarkScaledOnlyFallback() {
        let scaled = Self.entry(movement: Self.fran, score: .time(seconds: 390), isRx: false)
        let summary = PRResolver.summary(for: Self.fran, entries: [scaled])
        #expect(summary.bestRx == nil)
        #expect(summary.best == scaled)
    }

    @Test("Movement without Rx/scaled support keeps split empty")
    func nonBenchmarkHasNoSplit() {
        let single = Self.entry(score: .weight(kilograms: 120))
        let summary = PRResolver.summary(for: Self.backSquat, entries: [single])
        #expect(summary.best == single)
        #expect(summary.bestRx == nil)
        #expect(summary.bestScaled == nil)
    }

    // MARK: - Oracle edges (D1–D3 + PRD O5; documented behavior, see plan)

    // D3: an entry without an explicit Rx declaration is ranked as scaled —
    // the cautious reading (never inflates the Rx PR).
    @Test("isRx == nil on a benchmark counts as scaled, never as Rx")
    func isRxNilCountsAsScaled() {
        let undeclared = Self.entry(movement: Self.fran, score: .time(seconds: 400), isRx: nil)
        let summary = PRResolver.summary(for: Self.fran, entries: [undeclared])
        #expect(summary.bestRx == nil)
        #expect(summary.bestScaled == undeclared)
        #expect(summary.best == undeclared)
    }

    // Movement without Rx/scaled support ignores a stray flag entirely —
    // ranking stays single-bucket (FR-004: split only where supported).
    @Test("Stray isRx flags on a non-benchmark are ignored by the ranking")
    func strayRxFlagIgnoredWithoutSupport() {
        let flaggedRx = Self.entry(date: Self.day1, score: .weight(kilograms: 150), isRx: true)
        let flaggedScaled = Self.entry(date: Self.day2, score: .weight(kilograms: 140), isRx: false)
        let summary = PRResolver.summary(for: Self.backSquat, entries: [flaggedRx, flaggedScaled])
        #expect(summary.best == flaggedRx)
        #expect(summary.bestRx == nil)
        #expect(summary.bestScaled == nil)
    }

    // PRD O5 (tie -> newer date) asserted per score type, not only for weight.
    @Test("AMRAP tie (equal rounds and extra reps): newer date wins")
    func amrapTieNewerDateWins() {
        let older = Self.entry(movement: Self.cindy, date: Self.day1, score: .amrap(rounds: 6, extraReps: 7), isRx: true)
        let newer = Self.entry(movement: Self.cindy, date: Self.day2, score: .amrap(rounds: 6, extraReps: 7), isRx: true)
        let summary = PRResolver.summary(for: Self.cindy, entries: [older, newer])
        #expect(summary.bestRx == newer)
    }

    @Test("Time tie: newer date wins")
    func timeTieNewerDateWins() {
        let older = Self.entry(movement: Self.row500, date: Self.day1, score: .time(seconds: 89))
        let newer = Self.entry(movement: Self.row500, date: Self.day3, score: .time(seconds: 89))
        let summary = PRResolver.summary(for: Self.row500, entries: [newer, older])
        #expect(summary.best == newer)
    }

    @Test("Reps tie: newer date wins")
    func repsTieNewerDateWins() {
        let older = Self.entry(movement: Self.pullUp, date: Self.day1, score: .reps(count: 21))
        let newer = Self.entry(movement: Self.pullUp, date: Self.day2, score: .reps(count: 21))
        let summary = PRResolver.summary(for: Self.pullUp, entries: [older, newer])
        #expect(summary.best == newer)
    }

    // D2 dual: with only Rx entries the scaled slot stays empty and best is Rx.
    @Test("Benchmark with only Rx entries: bestScaled is nil, best is the Rx PR")
    func benchmarkRxOnly() {
        let rx = Self.entry(movement: Self.fran, score: .time(seconds: 490), isRx: true)
        let summary = PRResolver.summary(for: Self.fran, entries: [rx])
        #expect(summary.bestRx == rx)
        #expect(summary.bestScaled == nil)
        #expect(summary.best == rx)
    }

    // MARK: - Filtering and empties

    @Test("Entries of other movements are ignored")
    func otherMovementsIgnored() {
        let squat = Self.entry(score: .weight(kilograms: 150))
        let deadlift = Self.entry(movement: PRCatalog.movement(id: "deadlift")!, score: .weight(kilograms: 200))
        let summary = PRResolver.summary(for: Self.backSquat, entries: [squat, deadlift])
        #expect(summary.best == squat)
    }

    @Test("No entries: summary is empty")
    func emptyEntries() {
        let summary = PRResolver.summary(for: Self.backSquat, entries: [])
        #expect(summary.best == nil)
        #expect(summary.bestRx == nil)
        #expect(summary.bestScaled == nil)
    }

    // MARK: - Mismatched score types (D4)

    // D4: an entry whose score type disagrees with the movement's catalog type
    // must never become the PR — before this rule a mismatched entry with a
    // newer date won the silent tie (risk #1: loading weight off a bogus PR).
    @Test("Mismatched score type never beats a matching entry, even with a newer date")
    func mismatchedTypeNeverWins() {
        let bogus = Self.entry(date: Self.day3, score: .time(seconds: 300))
        let genuine = Self.entry(date: Self.day1, score: .weight(kilograms: 100))
        var summary = PRSummary(best: nil, bestRx: nil, bestScaled: nil)
        withKnownIssue("resolver reports the mismatched entry (dev telemetry)") {
            summary = PRResolver.summary(for: Self.backSquat, entries: [bogus, genuine])
        }
        #expect(summary.best == genuine)
    }

    // D4 boundary (impl-review F1): the partition is history-wide, not
    // per-bucket — one matching entry (even scaled) evicts a mismatched entry
    // from EVERY bucket, so a bogus Rx never occupies the Rx slot.
    @Test("Mismatched Rx entry vacates the Rx slot when a matching scaled entry exists")
    func mismatchedRxVacatesRxSlot() {
        let bogusRx = Self.entry(movement: Self.fran, date: Self.day2, score: .weight(kilograms: 100), isRx: true)
        let genuineScaled = Self.entry(movement: Self.fran, date: Self.day1, score: .time(seconds: 400), isRx: false)
        var summary = PRSummary(best: nil, bestRx: nil, bestScaled: nil)
        withKnownIssue("resolver reports the mismatched entry (dev telemetry)") {
            summary = PRResolver.summary(for: Self.fran, entries: [bogusRx, genuineScaled])
        }
        #expect(summary.bestRx == nil)
        #expect(summary.bestScaled == genuineScaled)
        #expect(summary.best == genuineScaled)
    }

    // D4 boundary: the preference only kicks in when a matching entry exists —
    // a mismatched-only history still surfaces a result (nothing hidden).
    @Test("Movement with only mismatched entries still surfaces one as best")
    func mismatchedOnlyStillSurfaces() {
        let bogus = Self.entry(date: Self.day1, score: .time(seconds: 300))
        var summary = PRSummary(best: nil, bestRx: nil, bestScaled: nil)
        withKnownIssue("resolver reports the mismatched entry (dev telemetry)") {
            summary = PRResolver.summary(for: Self.backSquat, entries: [bogus])
        }
        #expect(summary.best == bogus)
    }

    // MARK: - Category helpers

    @Test("completedMovementIds collects distinct movements")
    func completedMovementIds() {
        let entries = [
            Self.entry(score: .weight(kilograms: 100)),
            Self.entry(score: .weight(kilograms: 110)),
            Self.entry(movement: Self.pullUp, score: .reps(count: 15)),
        ]
        #expect(PRResolver.completedMovementIds(entries: entries) == ["back-squat", "pull-up"])
    }

    @Test("latestEntryDate returns the newest day")
    func latestEntryDate() {
        let entries = [
            Self.entry(date: Self.day1, score: .weight(kilograms: 100)),
            Self.entry(date: Self.day3, score: .weight(kilograms: 90)),
            Self.entry(date: Self.day2, score: .weight(kilograms: 95)),
        ]
        #expect(PRResolver.latestEntryDate(entries: entries) == Self.day3)
        #expect(PRResolver.latestEntryDate(entries: []) == nil)
    }
}
