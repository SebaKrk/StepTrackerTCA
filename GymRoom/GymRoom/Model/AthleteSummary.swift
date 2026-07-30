//
//  AthleteSummary.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import Foundation
import SharedModels

/// Domain wrapper dla decoded `AthleteSessionRecord` — używany w ClassHistoryDetail.
///
/// Reducer fetch'uje `AthleteSessionRecord` z bazy, decoduje BLOB-y
/// (`hrSamplesData` → `[HRSample]`, `aggregatedStatsData` → `ClassAnalytics`)
/// raz w `viewDidAppear`, propaguje do State jako `[AthleteSummary]`. View
/// konsumuje **decoded** structures bez JSONDecoder calls w body (performance).
struct AthleteSummary: Identifiable, Sendable, Equatable {
    let id: UUID                  // = AthleteSessionRecord.id
    let deviceID: UUID            // stable per-install peer ID (do color mapping)
    let nick: String              // display name
    let maxHR: Int                // snapshot z momentu pierwszego sample
    let joinedAt: Date
    let leftAt: Date?
    let samples: [HRSample]       // decoded chronological
    let analytics: ClassAnalytics // decoded aggregates
}

// MARK: - Gap-aware chart segmentation

extension AthleteSummary {

    /// A continuous run of samples with no measurement gap. Each segment is drawn
    /// as a SEPARATE `LineMark` series — Swift Charts connects all points within
    /// one series, so without segmentation an outage (athlete out of BLE range)
    /// gets bridged with a straight line across the gap.
    struct HRSegment: Identifiable, Sendable, Equatable {
        let id: Int
        let samples: [HRSample]
    }

    /// Max distance between consecutive samples still considered continuous.
    /// Peers deliver HR every few seconds, but brief BLE hiccups are common —
    /// a full minute of silence means the athlete actually left the range and
    /// the chart should show a gap; anything shorter must NOT shred the line
    /// into confetti (user decision 2026-07-06: 15s was too aggressive).
    static let maxContinuousSampleGap: TimeInterval = 60

    /// A measurement outage between two continuous segments (athlete out of BLE
    /// range). Rendered on per-athlete cards as a shaded vertical band so the
    /// empty stretch reads as "no measurement", not "no effort".
    struct HRGap: Identifiable, Sendable, Equatable {
        var id: Date { start }
        let start: Date
        let end: Date

        /// Band edges snapped to the minute grid of the range-bar chart. Bars occupy
        /// whole-minute buckets (`unit: .minute`) while gap endpoints are raw sample
        /// timestamps — unsnapped edges cut through the neighboring buckets, so the
        /// boundary bars rendered half-inside the band ("najeżdżanie", 2026-07-06).
        /// Covers only FULLY empty minutes; `nil` when the gap has none (band would
        /// have zero/negative width — nothing worth shading at minute resolution).
        var minuteAlignedBand: ClosedRange<Date>? {
            let calendar = Calendar.current
            guard
                let lastMeasuredMinute = calendar.dateInterval(of: .minute, for: start),
                let resumedMinute = calendar.dateInterval(of: .minute, for: end)
            else { return nil }
            let bandStart = lastMeasuredMinute.end     // first fully empty minute
            let bandEnd = resumedMinute.start          // bucket of the resume bar
            guard bandStart < bandEnd else { return nil }
            return bandStart...bandEnd
        }
    }

    /// Derives outage intervals from already-split segments — a gap spans from the
    /// last sample of one segment to the first sample of the next. O(segments).
    static func measurementGaps(from segments: [HRSegment]) -> [HRGap] {
        guard segments.count > 1 else { return [] }
        return zip(segments, segments.dropFirst()).compactMap { previous, next in
            guard
                let gapStart = previous.samples.last?.timestamp,
                let gapEnd = next.samples.first?.timestamp
            else { return nil }
            return HRGap(start: gapStart, end: gapEnd)
        }
    }

    /// Splits `samples` into continuous segments at measurement gaps.
    /// O(n) — call once at load time (mirrors the `minuteRanges` precompute
    /// pattern), NOT in a view body: scrubbing re-evaluates the chart per frame.
    static func hrSegments(from samples: [HRSample]) -> [HRSegment] {
        guard !samples.isEmpty else { return [] }
        var segments: [[HRSample]] = [[]]
        var previousTimestamp: Date?
        for sample in samples {
            if let previousTimestamp,
               sample.timestamp.timeIntervalSince(previousTimestamp) > maxContinuousSampleGap {
                segments.append([])
            }
            segments[segments.count - 1].append(sample)
            previousTimestamp = sample.timestamp
        }
        return segments.enumerated().map { HRSegment(id: $0.offset, samples: $0.element) }
    }
}
