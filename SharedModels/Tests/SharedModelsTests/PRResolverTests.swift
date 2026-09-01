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
/// rankings, ties resolved by newer date then newer save timestamp.
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
