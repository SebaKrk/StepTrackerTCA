//
//  HeartRateZoneClassificationTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 17/07/2026.
//

import Foundation
import Testing
@testable import SharedModels

@Suite("HeartRateZone.zone(forFraction:)")
struct HeartRateZoneClassificationTests {

    // Golden boundary table — the whole point of the shared helper is that
    // every surface (iPhone, Watch, iPad, analytics) agrees on these exact
    // values. A boundary belongs to the zone it OPENS (lower-inclusive):
    // 0.70 is Zone 3, not Zone 2. Do not change without a user decision —
    // ambiguous bounds once made the same 70% show two different colors.
    @Test("Boundaries are lower-inclusive", arguments: [
        (0.0, HeartRateZone.resting),
        (0.49, HeartRateZone.resting),
        (0.5, HeartRateZone.recovery),
        (0.59, HeartRateZone.recovery),
        (0.6, HeartRateZone.fatBurning),
        (0.699, HeartRateZone.fatBurning),
        (0.7, HeartRateZone.aerobic),
        (0.79, HeartRateZone.aerobic),
        (0.8, HeartRateZone.threshold),
        (0.89, HeartRateZone.threshold),
        (0.9, HeartRateZone.anaerobic),
        (1.0, HeartRateZone.anaerobic),
    ])
    func boundaries(fraction: Double, expected: HeartRateZone) {
        #expect(HeartRateZone.zone(forFraction: fraction) == expected)
    }

    @Test("Supra-max stays Zone 5 — estimated maxHR is routinely exceeded")
    func supraMaxIsAnaerobic() {
        // Real case from the field: peak 198 bpm vs formula-estimated max 190.
        #expect(HeartRateZone.zone(forFraction: 198.0 / 190.0) == .anaerobic)
        #expect(HeartRateZone.zone(forFraction: 1.5) == .anaerobic)
    }

    @Test("Nonsense input degrades to resting, never crashes")
    func negativeIsResting() {
        #expect(HeartRateZone.zone(forFraction: -0.1) == .resting)
    }

    @Test("bpm/maxHR overload guards the division — missing maxHR is resting, not fake Zone 5")
    func missingMaxHRIsResting() {
        // Without the guard, bpm/0 = +inf would fall into the classifier's
        // `default:` case and read as maximal effort for an athlete whose
        // capacity we simply don't know.
        #expect(HeartRateZone.zone(bpm: 150, maxHR: 0) == .resting)
        #expect(HeartRateZone.zone(bpm: 134, maxHR: 190) == .aerobic)
    }

    @Test("Raw fraction and its truncated display percent agree on the zone")
    func rawFractionAgreesWithDisplayedPercent() {
        // 134 bpm / 190 maxHR = 0.7053: the iPad used to truncate to 70% first
        // and (with upper-inclusive bounds) show Zone 2 green, while the iPhone
        // classified the raw value as Zone 3 yellow — the reported mismatch.
        // With lower-inclusive bounds the displayed "70%" and the raw fraction
        // land in the SAME zone, so the number and the color tell one story.
        let raw = 134.0 / 190.0
        let truncatedDisplay = Double(Int(raw * 100)) / 100
        #expect(HeartRateZone.zone(forFraction: raw) == .aerobic)
        #expect(HeartRateZone.zone(forFraction: truncatedDisplay) == .aerobic)
    }
}
