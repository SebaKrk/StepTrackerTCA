//
//  ClassAnalytics+Compute.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation

extension ClassAnalytics {

    /// Sentinel pusty snapshot — używany przy create athlete record'u zanim pojawi się
    /// pierwsza próbka. Po `peerDisconnected` nadpisywany przez `compute(...)` wynik.
    public static let empty = ClassAnalytics(
        avgHR: 0,
        peakHR: 0,
        totalCalories: 0,
        durationSeconds: 0,
        timeInZones: [:]
    )

    /// Computuje aggregated stats z surowego strumienia `[HRSample]` athlete'a.
    ///
    /// **Algorytm**:
    /// - `avgHR` — średnia z `samples.bpm` (sum / count, rounded do Int)
    /// - `peakHR` — `max(samples.bpm)`
    /// - `totalCalories` — **delta** `lastSample.activeEnergy - firstSample.activeEnergy`
    ///   (nie suma — `activeEnergy` w peer'ze to cumulative kcal od Start Workout Watcha,
    ///   więc sumowanie byłoby błędne)
    /// - `timeInZones` — iteruje po samples, dla każdego `%HR = bpm/maxHR`, znajduje
    ///   strefę z `HeartRateZone.percentageRange`, akumuluje `(next.timestamp - current.timestamp)`
    /// - `durationSeconds` — `duration` parameter (pass z reducer'a: `leftAt - joinedAt`)
    ///
    /// **Edge cases**:
    /// - Empty samples → `.empty` (zero everything, brak crash'u na divide-by-zero)
    /// - `maxHR == 0` (peer wysłał nieustalony) → `timeInZones` empty (skip zone matching)
    /// - Gap'y w samples (peer disconnect mid-class) — czas między próbkami liczy się
    ///   normalnie do strefy *poprzedniej* próbki (assume sustained HR przez gap)
    public static func compute(
        samples: [HRSample],
        maxHR: Int,
        duration: TimeInterval
    ) -> ClassAnalytics {
        guard !samples.isEmpty else { return .empty }

        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }

        let avgHR = Int(round(Double(sortedSamples.reduce(0) { $0 + $1.bpm }) / Double(sortedSamples.count)))
        let peakHR = sortedSamples.map(\.bpm).max() ?? 0
        let totalCalories = (sortedSamples.last?.activeEnergy ?? 0) - (sortedSamples.first?.activeEnergy ?? 0)

        let timeInZones = computeTimeInZones(samples: sortedSamples, maxHR: maxHR)

        // Device-computed cumulative counter — the final total is the last
        // reported value (goodbye payloads carry it too). Last non-nil, not
        // last sample: an old-build goodbye must not wipe a known total.
        let effortPoints = sortedSamples.reversed().compactMap(\.effortPoints).first

        return ClassAnalytics(
            avgHR: avgHR,
            peakHR: peakHR,
            totalCalories: max(0, totalCalories),
            durationSeconds: duration,
            timeInZones: timeInZones,
            effortPoints: effortPoints
        )
    }

    /// Iteruje po posortowanych chronologicznie samples, dla każdego klasyfikuje
    /// `%HR` do strefy, akumuluje delta-time do następnej próbki.
    ///
    /// Ostatnia próbka kontrybuuje 0s (brak następnej do delta) — pomijalne dla 1Hz stream'u,
    /// długiej klasy. Alternatywa: użyj `duration - elapsed` dla ostatniej próbki, ale
    /// 1s drift na 3600s session = 0.03% błąd.
    private static func computeTimeInZones(
        samples: [HRSample],
        maxHR: Int
    ) -> [HeartRateZone: TimeInterval] {
        guard maxHR > 0 else { return [:] }

        var timeInZones: [HeartRateZone: TimeInterval] = [:]

        for index in 0..<(samples.count - 1) {
            let sample = samples[index]
            let nextSample = samples[index + 1]
            let delta = nextSample.timestamp.timeIntervalSince(sample.timestamp)

            // Shared classifier — supra-max samples land in Zone 5 instead of
            // silently dropping out of the distribution (the old range lookup
            // matched nothing above 1.0 and lost the hardest seconds of a class).
            let zone = HeartRateZone.zone(forFraction: Double(sample.bpm) / Double(maxHR))
            timeInZones[zone, default: 0] += delta
        }

        return timeInZones
    }
}
