//
//  RoundsAnalysis.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/09/2026.
//

import Foundation

/// Post-hoc heart-rate analysis of a rounds-timer workout: HR samples cut by
/// the `RoundSegment` timeline read back from the workout's events. Pure value
/// computation — no HealthKit, no clocks — so every number is reproducible
/// from the workout at any time.
public struct RoundsAnalysis: Equatable, Sendable {

    /// HR profile of one completed work segment.
    public struct Round: Equatable, Sendable, Identifiable {

        /// 1-based round number (same as on the timer tile).
        public let index: Int

        /// Lowest HR sample inside the round.
        public let minHR: Int

        /// Mean HR across the round's samples.
        public let avgHR: Int

        /// Highest HR sample inside the round.
        public let peakHR: Int

        /// Actual wall-clock length of the round (pauses/skips included).
        public let duration: TimeInterval

        /// Active energy burned inside the round; nil when the workout carries
        /// no energy samples at all (line hidden in UI).
        public let kcal: Double?

        public var id: Int { index }
    }

    /// How much the athlete recovered during one rest segment.
    public struct Recovery: Equatable, Sendable, Identifiable {

        /// The round this rest followed.
        public let afterRound: Int

        /// Peak around the round's end minus the HR at the rest's end,
        /// clamped at 0 — "recovery" cannot be negative; 0 reads as none.
        public let dropBPM: Int

        /// HR at the rest's end — classifies the ZONE the athlete recovered to,
        /// which colors the recovery bar (system zone palette, no custom hues).
        public let endHR: Int

        /// Anchor peak the drop was measured from — the bar's gradient runs
        /// from this HR's zone (top) down to `endHR`'s zone (bottom).
        public let peakHR: Int

        /// Actual wall-clock length of the rest.
        public let duration: TimeInterval

        /// Active energy burned during the rest; nil when the workout carries
        /// no energy samples at all.
        public let kcal: Double?

        public var id: Int { afterRound }
    }

    /// Completed rounds that had at least one HR sample, in order.
    public let rounds: [Round]

    /// Recoveries for rests that had samples, in order.
    public let recoveries: [Recovery]

    /// Mean of the rounds' average HRs.
    public let averageWorkHR: Int

    /// Mean recovery drop; nil when no rest carried samples (e.g. rest = 0 s).
    public let averageDrop: Int?

    /// Round with the highest peak HR.
    public let hardestRound: Round?

    /// First round after which recovery collapses — two consecutive drops below
    /// 60% of the early-workout baseline (median of the first three drops).
    /// nil when there are too few rests to judge (fewer than five).
    public let recoveryFadeAfterRound: Int?
}

// MARK: - Calculator

extension RoundsAnalysis {

    /// Window at the end of a round whose peak anchors the recovery drop —
    /// the whole-round peak may sit in an early flurry, not where rest began.
    private static let recoveryAnchorWindow: TimeInterval = 10

    /// HR keeps climbing for a few seconds after the bell (cardiac lag), so the
    /// anchor window spills into the rest — otherwise the real peak is missed
    /// and the drop comes out understated or negative.
    private static let recoveryAnchorSpillover: TimeInterval = 5

    /// Drops below this fraction of the early baseline count as "faded".
    private static let fadeThreshold = 0.6

    /// Cuts raw HR samples by the segment timeline. Returns nil when no round
    /// carries a single sample (sensor never delivered) — callers hide the UI.
    public static func analyze(
        samples: [(date: Date, bpm: Double)],
        energySamples: [(date: Date, kcal: Double)] = [],
        segments: [RoundSegment]
    ) -> RoundsAnalysis? {
        let workSegments = segments.filter { $0.kind == .work }
        let restSegments = segments.filter { $0.kind == .rest }
        let hasEnergy = !energySamples.isEmpty
        func kcal(in interval: DateInterval) -> Double? {
            guard hasEnergy else { return nil }
            return energySamples
                .filter { interval.contains($0.date) }
                .reduce(0) { $0 + $1.kcal }
        }

        let rounds: [Round] = workSegments.compactMap { segment in
            let bpms = samples
                .filter { segment.dateInterval.contains($0.date) }
                .map(\.bpm)
            guard !bpms.isEmpty else { return nil }
            return Round(
                index: segment.roundIndex,
                minHR: Int(bpms.min()!.rounded()),
                avgHR: Int((bpms.reduce(0, +) / Double(bpms.count)).rounded()),
                peakHR: Int(bpms.max()!.rounded()),
                duration: segment.dateInterval.duration,
                kcal: kcal(in: segment.dateInterval)
            )
        }
        guard !rounds.isEmpty else { return nil }

        let recoveries: [Recovery] = restSegments.compactMap { rest in
            guard let work = workSegments.first(where: { $0.roundIndex == rest.roundIndex }) else { return nil }
            let anchorStart = work.dateInterval.end.addingTimeInterval(-Self.recoveryAnchorWindow)
            let anchorEnd = work.dateInterval.end.addingTimeInterval(Self.recoveryAnchorSpillover)
            let anchorPeak = samples
                .filter { $0.date >= anchorStart && $0.date <= anchorEnd }
                .map(\.bpm)
                .max()
                ?? samples.filter { work.dateInterval.contains($0.date) }.map(\.bpm).max()
            guard let peak = anchorPeak,
                  let restEnd = samples.filter({ rest.dateInterval.contains($0.date) }).max(by: { $0.date < $1.date })
            else { return nil }
            return Recovery(
                afterRound: rest.roundIndex,
                dropBPM: max(0, Int((peak - restEnd.bpm).rounded())),
                endHR: Int(restEnd.bpm.rounded()),
                peakHR: Int(peak.rounded()),
                duration: rest.dateInterval.duration,
                kcal: kcal(in: rest.dateInterval)
            )
        }

        let averageWorkHR = Int((Double(rounds.map(\.avgHR).reduce(0, +)) / Double(rounds.count)).rounded())
        let averageDrop = recoveries.isEmpty
            ? nil
            : Int((Double(recoveries.map(\.dropBPM).reduce(0, +)) / Double(recoveries.count)).rounded())

        return RoundsAnalysis(
            rounds: rounds,
            recoveries: recoveries,
            averageWorkHR: averageWorkHR,
            averageDrop: averageDrop,
            hardestRound: rounds.max { ($0.peakHR, $0.avgHR) < ($1.peakHR, $1.avgHR) },
            recoveryFadeAfterRound: fadeRound(in: recoveries)
        )
    }

    /// Two consecutive drops below 60% of the median of the first three =
    /// the fade point; needs at least five rests to say anything.
    private static func fadeRound(in recoveries: [Recovery]) -> Int? {
        guard recoveries.count >= 5 else { return nil }
        let baseline = median(recoveries.prefix(3).map { Double($0.dropBPM) })
        guard baseline > 0 else { return nil }
        let cutoff = baseline * Self.fadeThreshold
        for index in recoveries.indices.dropLast() where index >= 1 {
            if Double(recoveries[index].dropBPM) < cutoff,
               Double(recoveries[index + 1].dropBPM) < cutoff {
                return recoveries[index].afterRound
            }
        }
        return nil
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted.count.isMultiple(of: 2)
            ? (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
            : sorted[sorted.count / 2]
    }
}
