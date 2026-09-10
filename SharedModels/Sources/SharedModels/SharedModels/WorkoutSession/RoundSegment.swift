//
//  RoundSegment.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/09/2026.
//

import Foundation
import HealthKit

/// One completed segment of the boxing-rounds timer, persisted natively as an
/// `HKWorkoutEvent(.segment)` on the workout itself — HealthKit is the single
/// source of truth, no app-side table. Records FACTS (a session pause stretches
/// the interval, a skipped segment ends early), never the planned config.
public struct RoundSegment: Codable, Equatable, Sendable {

    /// Whether the athlete was boxing or recovering.
    public enum Kind: String, Codable, Sendable {
        /// Work segment (the round itself).
        case work
        /// Rest between rounds.
        case rest
    }

    /// 1-based round number the segment belongs to.
    public let roundIndex: Int

    /// Work or rest.
    public let kind: Kind

    /// Actual wall-clock span of the segment.
    public let dateInterval: DateInterval

    public init(roundIndex: Int, kind: Kind, dateInterval: DateInterval) {
        self.roundIndex = roundIndex
        self.kind = kind
        self.dateInterval = dateInterval
    }
}

// MARK: - HKWorkoutEvent bridge

extension RoundSegment {

    /// Custom metadata keys carried by the `.segment` event — they distinguish
    /// OUR rounds from segments marked by other apps or by hand.
    public enum MetadataKey {
        public static let roundIndex = "ss.rounds.index"
        public static let kind = "ss.rounds.kind"
    }

    /// The HealthKit event persisting this segment on the live builder.
    public var workoutEvent: HKWorkoutEvent {
        HKWorkoutEvent(
            type: .segment,
            dateInterval: dateInterval,
            metadata: [
                MetadataKey.roundIndex: roundIndex,
                MetadataKey.kind: kind.rawValue
            ]
        )
    }

    /// Parses our round segments out of a workout's events, sorted by start.
    /// Foreign `.segment` events lack the metadata keys and are skipped.
    public static func segments(from events: [HKWorkoutEvent]?) -> [RoundSegment] {
        (events ?? [])
            .compactMap { event -> RoundSegment? in
                guard event.type == .segment,
                      let roundIndex = event.metadata?[MetadataKey.roundIndex] as? Int,
                      let kindRaw = event.metadata?[MetadataKey.kind] as? String,
                      let kind = Kind(rawValue: kindRaw)
                else { return nil }
                return RoundSegment(roundIndex: roundIndex, kind: kind, dateInterval: event.dateInterval)
            }
            .sorted { $0.dateInterval.start < $1.dateInterval.start }
    }
}
