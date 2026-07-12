//
//  EffortPointsTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import Foundation
import Testing
@testable import SharedModels

@Suite("EffortPointsScoring")
struct EffortPointsScoringTests {

    // Curve 1·2·4·6·6: 8·1 + 15·2 + 20·4 + 10·6 + 2·6 = 8+30+80+60+12 = 190.
    @Test("Reference session: 8'Z1 + 15'Z2 + 20'Z3 + 10'Z4 + 2'Z5 = 190 points")
    func referenceSession() {
        let timeInZones: [HeartRateZone: TimeInterval] = [
            .recovery: 8 * 60,
            .fatBurning: 15 * 60,
            .aerobic: 20 * 60,
            .threshold: 10 * 60,
            .anaerobic: 2 * 60,
        ]
        #expect(EffortPointsScoring.points(from: timeInZones) == 190)
    }

    @Test("Zone 5 is capped at Zone 4's rate — no bonus for lingering in the red")
    func zone5CappedAtZone4() {
        let oneMinuteZone4: [HeartRateZone: TimeInterval] = [.threshold: 60]
        let oneMinuteZone5: [HeartRateZone: TimeInterval] = [.anaerobic: 60]
        #expect(EffortPointsScoring.points(from: oneMinuteZone4) == 6)
        #expect(EffortPointsScoring.points(from: oneMinuteZone5) == 6)
    }

    @Test("Per-zone breakdown always sums to the total (largest-remainder)")
    func pointsByZoneSumsToTotal() {
        // Fractional case designed to force rounding drift: 90s in Z3 (6.0),
        // 30s in Z2 (1.0), 45s in Z4 (4.5), 15s in Z1 (0.25) → exact 11.75 → total 12.
        let timeInZones: [HeartRateZone: TimeInterval] = [
            .recovery: 15, .fatBurning: 30, .aerobic: 90, .threshold: 45,
        ]
        let total = EffortPointsScoring.points(from: timeInZones)
        let breakdown = EffortPointsScoring.pointsByZone(from: timeInZones)
        #expect(breakdown.values.reduce(0, +) == total)
    }

    @Test("Per-zone breakdown matches reference session and sums to 190")
    func pointsByZoneReference() {
        let timeInZones: [HeartRateZone: TimeInterval] = [
            .recovery: 8 * 60, .fatBurning: 15 * 60, .aerobic: 20 * 60,
            .threshold: 10 * 60, .anaerobic: 2 * 60,
        ]
        let breakdown = EffortPointsScoring.pointsByZone(from: timeInZones)
        #expect(breakdown[.recovery] == 8)
        #expect(breakdown[.fatBurning] == 30)
        #expect(breakdown[.aerobic] == 80)
        #expect(breakdown[.threshold] == 60)
        #expect(breakdown[.anaerobic] == 12)
        #expect(breakdown.values.reduce(0, +) == 190)
    }

    @Test("Resting time earns nothing")
    func restingEarnsNothing() {
        let timeInZones: [HeartRateZone: TimeInterval] = [.resting: 45 * 60]
        #expect(EffortPointsScoring.points(from: timeInZones) == 0)
    }

    @Test("Empty distribution scores zero")
    func emptyDistribution() {
        #expect(EffortPointsScoring.points(from: [:]) == 0)
    }

    @Test("Partial minutes score fractionally — 90s in Zone 3 = 6 points")
    func partialMinutes() {
        #expect(EffortPointsScoring.points(from: [.aerobic: 90]) == 6)
    }

    @Test("Reading above maxHR counts as Zone 5")
    func aboveMaxCountsAsZone5() {
        #expect(EffortPointsScoring.zone(bpm: 210, maxHR: 190) == .anaerobic)
    }

    @Test("Zone lookup matches percentage ranges")
    func zoneLookup() {
        #expect(EffortPointsScoring.zone(bpm: 80, maxHR: 200) == .resting)     // 40%
        #expect(EffortPointsScoring.zone(bpm: 110, maxHR: 200) == .recovery)   // 55%
        #expect(EffortPointsScoring.zone(bpm: 130, maxHR: 200) == .fatBurning) // 65%
        #expect(EffortPointsScoring.zone(bpm: 150, maxHR: 200) == .aerobic)    // 75%
        #expect(EffortPointsScoring.zone(bpm: 170, maxHR: 200) == .threshold)  // 85%
        #expect(EffortPointsScoring.zone(bpm: 190, maxHR: 200) == .anaerobic)  // 95%
    }
}

@Suite("EffortPointsAccumulator")
struct EffortPointsAccumulatorTests {

    @Test("Incremental accumulation matches the aggregate path")
    func matchesAggregatePath() {
        var accumulator = EffortPointsAccumulator()
        // 10 minutes in Zone 3 (75% of 200), fed as 1-second samples.
        for _ in 0..<600 {
            accumulator.add(bpm: 150, duration: 1, maxHR: 200)
        }
        #expect(accumulator.points == EffortPointsScoring.points(from: [.aerobic: 600]))
        #expect(accumulator.points == 40)
    }

    @Test("Ignores sensor artifacts and unconfigured max")
    func ignoresInvalidInput() {
        var accumulator = EffortPointsAccumulator()
        accumulator.add(bpm: 0, duration: 60, maxHR: 200)   // sensor artifact
        accumulator.add(bpm: 150, duration: 0, maxHR: 200)  // zero duration
        accumulator.add(bpm: 150, duration: -5, maxHR: 200) // negative duration
        accumulator.add(bpm: 150, duration: 60, maxHR: 0)   // maxHR not configured
        #expect(accumulator.points == 0)
        #expect(accumulator.secondsByZone.isEmpty)
    }

    @Test("Measurement gap longer than 5 minutes is not credited")
    func skipsImplausibleGap() {
        var accumulator = EffortPointsAccumulator()
        accumulator.add(bpm: 150, duration: 301, maxHR: 200)
        #expect(accumulator.points == 0)
    }

    @Test("Strap outage story: stale repeats and the outage stretch earn nothing (IOS-00100-A)")
    func strapOutageStory() {
        var accumulator = EffortPointsAccumulator()
        // 2 honest minutes of Zone 3 before running out of BLE range.
        for _ in 0..<4 {
            accumulator.add(bpm: 150, duration: 30, maxHR: 200)
        }
        let honestPoints = accumulator.points
        // Outage: the builder keeps repeating the frozen value, but the sample
        // date does not move — the freshness gate reduces every repeat to a
        // zero-duration add, which must not credit anything.
        for _ in 0..<10 {
            accumulator.add(bpm: 150, duration: 0, maxHR: 200)
        }
        // Return after a 6-minute stretch with no real samples — the delta to
        // the previous REAL sample exceeds the 5-minute guard and is dropped.
        accumulator.add(bpm: 165, duration: 360, maxHR: 200)
        #expect(accumulator.points == honestPoints)
    }

    @Test("Reset clears the counter")
    func resetClears() {
        var accumulator = EffortPointsAccumulator()
        accumulator.add(bpm: 170, duration: 120, maxHR: 200)
        #expect(accumulator.points > 0)
        accumulator.reset()
        #expect(accumulator.points == 0)
        #expect(accumulator.secondsByZone.isEmpty)
    }
}

@Suite("ClassAnalytics effort points")
struct ClassAnalyticsEffortPointsTests {

    @Test("Final total is the last non-nil value — an old-build goodbye does not wipe it")
    func lastNonNilWins() {
        let start = Date(timeIntervalSince1970: 0)
        let samples = [
            HRSample(timestamp: start, bpm: 120, activeEnergy: 0, effortPoints: 10),
            HRSample(timestamp: start.addingTimeInterval(60), bpm: 130, activeEnergy: 5, effortPoints: 12),
            HRSample(timestamp: start.addingTimeInterval(120), bpm: 0, activeEnergy: 5, effortPoints: nil),
        ]
        let analytics = ClassAnalytics.compute(samples: samples, maxHR: 190, duration: 120)
        #expect(analytics.effortPoints == 12)
    }

    @Test("Samples without effort points decode to nil total (pre-feature blobs)")
    func allNilStaysNil() {
        let start = Date(timeIntervalSince1970: 0)
        let samples = [
            HRSample(timestamp: start, bpm: 120, activeEnergy: 0),
            HRSample(timestamp: start.addingTimeInterval(60), bpm: 130, activeEnergy: 5),
        ]
        let analytics = ClassAnalytics.compute(samples: samples, maxHR: 190, duration: 60)
        #expect(analytics.effortPoints == nil)
    }
}
