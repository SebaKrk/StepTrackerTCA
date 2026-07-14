//
//  HRSample+Aggregation.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import Foundation

extension HRSample {

    /// Grupuje `[HRSample]` po początku bucketu o szerokości `bucketSeconds`,
    /// redukuje do `[HRMinuteRange]` z `(minHR, maxHR)` per bucket. Wynik sortowany
    /// rosnąco po `minute` (= bucket start).
    ///
    /// **Bucket boundaries** — floor'owane do wielokrotności `bucketSeconds` od
    /// `referenceDate`. Np. dla `bucketSeconds: 30` bucketów są na `:00` i `:30`
    /// każdej minuty. Dla `60` — na początku każdej minuty (równoważne `minuteRanges`).
    ///
    /// **Czysta funkcja** — bez side effects, testowalna w izolacji. Wołać off
    /// main thread (3600 sample'ów × N athletes nie jest darmowe).
    ///
    /// **Edge case**: empty input → empty output. Brak crash'u na nil min/max.
    public static func ranges(from samples: [HRSample], bucketSeconds: TimeInterval) -> [HRMinuteRange] {
        guard !samples.isEmpty else { return [] }

        let grouped = Dictionary(grouping: samples) { sample -> Date in
            let interval = sample.timestamp.timeIntervalSinceReferenceDate
            let bucketIndex = floor(interval / bucketSeconds)
            return Date(timeIntervalSinceReferenceDate: bucketIndex * bucketSeconds)
        }

        return grouped
            .map { bucketStart, bucket in
                let bpms = bucket.map(\.bpm)
                return HRMinuteRange(
                    minute: bucketStart,
                    minHR: bpms.min() ?? 0,
                    maxHR: bpms.max() ?? 0
                )
            }
            .sorted { $0.minute < $1.minute }
    }

    /// Convenience: 60-sek bucketing (kalendarzowe minuty). Równoważne
    /// `ranges(from:, bucketSeconds: 60)`.
    public static func minuteRanges(from samples: [HRSample]) -> [HRMinuteRange] {
        ranges(from: samples, bucketSeconds: 60)
    }
}
