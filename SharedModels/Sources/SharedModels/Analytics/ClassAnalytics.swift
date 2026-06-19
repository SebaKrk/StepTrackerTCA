//
//  ClassAnalytics.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation

/// Aggregated stats per athlete w jednej klasie — computed z `[HRSample]` na koniec
/// session'a athlete'a (`peerDisconnected` / class end / grace timeout).
///
/// **Storage**: JSON-encoded w `AthleteSessionRecord.aggregatedStatsData` BLOB.
/// Snapshot — raz policzony, nie re-compute (raw samples zostają w `hrSamplesData`
/// gdy ktoś będzie chciał recompute'ować np. po zmianie maxHR).
///
/// **Charts mapping** (subtask E):
/// - `totalCalories` → bar chart top calories burned per athlete
/// - `avgHR` / `peakHR` → top stats banner
/// - `timeInZones` → pie chart aggregated time in HR zones (5 colors)
/// - `durationSeconds` → row subtitle "1h 12min"
public struct ClassAnalytics: Codable, Sendable, Equatable {

    /// Średnia HR z sample'i (sum(bpm) / count). Rounded do Int.
    public let avgHR: Int

    /// Najwyższe HR z całej session'a — chwilowy peak.
    public let peakHR: Int

    /// Łączny active energy spalony przez athlete'a w klasie (kcal cumulative).
    public let totalCalories: Double

    /// Czas trwania session'a athlete'a (sekundy między `joinedAt` a `leftAt`).
    /// `TimeInterval` (Double) bo Foundation API zwracają Double.
    public let durationSeconds: TimeInterval

    /// Czas spędzony w każdej z 5 stref HR (sekundy). Może być pusty dla bardzo
    /// krótkich session'ów (<1s próbka). Suma ≤ `durationSeconds` (gap'y w samples
    /// nie są policzane).
    public let timeInZones: [HeartRateZone: TimeInterval]

    public init(
        avgHR: Int,
        peakHR: Int,
        totalCalories: Double,
        durationSeconds: TimeInterval,
        timeInZones: [HeartRateZone: TimeInterval]
    ) {
        self.avgHR = avgHR
        self.peakHR = peakHR
        self.totalCalories = totalCalories
        self.durationSeconds = durationSeconds
        self.timeInZones = timeInZones
    }
}
