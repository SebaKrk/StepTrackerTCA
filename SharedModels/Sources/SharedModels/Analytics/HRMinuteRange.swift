//
//  HRMinuteRange.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import Foundation

/// Agregat min/max BPM w obrębie jednej minuty kalendarzowej.
///
/// **Producer**: `HRSample.minuteRanges(from:)` — czysta funkcja groupująca surowe
/// próbki @ 1Hz po `.minute` kalendarzowej, redukująca do `(min, max)` per bucket.
///
/// **Consumer**: `ClassHistoryDetailFeature.State.hrRangesByAthlete` — pre-computed
/// w `viewDidAppear` po decode BLOB-ów, rysowany jako `BarMark(yStart:yEnd:)`
/// (range bar chart per athlete).
///
/// **Czemu Int a nie Double**: `HRSample.bpm: Int` (peer wysyła zaokrąglone BPM),
/// więc range też Int — bez sztucznej precyzji.
public struct HRMinuteRange: Sendable, Equatable, Codable, Identifiable {

    /// Początek minuty kalendarzowej (np. 12:34:00). ID dla `ForEach`.
    public let minute: Date

    /// Najniższy BPM odnotowany w tej minucie.
    public let minHR: Int

    /// Najwyższy BPM odnotowany w tej minucie.
    public let maxHR: Int

    public var id: Date { minute }

    public init(minute: Date, minHR: Int, maxHR: Int) {
        self.minute = minute
        self.minHR = minHR
        self.maxHR = maxHR
    }
}
