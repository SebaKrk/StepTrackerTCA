//
//  SleepSession.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// A single continuous sleep session reconstructed from HealthKit samples.
///
/// HealthKit stores sleep as many short stage samples, often duplicated across
/// devices. A session groups them back into one night, so readiness can ask
/// "when did the user wake up" instead of guessing with a fixed clock hour.
public struct SleepSession: Sendable, Equatable {

    /// When the user fell asleep — start of the earliest sample in the session.
    public let start: Date

    /// When the user woke up — end of the latest sample in the session.
    public let end: Date

    /// Time actually spent asleep, with awake gaps and duplicates removed.
    ///
    /// Always shorter than `end.timeIntervalSince(start)` when the night had
    /// awakenings, which is why it cannot be derived from the bounds.
    public let asleepDuration: TimeInterval

    /// Creates a sleep session.
    ///
    /// - Parameters:
    ///   - start: Start of the earliest sample
    ///   - end: End of the latest sample
    ///   - asleepDuration: Deduplicated time asleep, in seconds
    public init(start: Date, end: Date, asleepDuration: TimeInterval) {
        self.start = start
        self.end = end
        self.asleepDuration = asleepDuration
    }

    /// Time actually spent asleep, expressed in hours.
    public var asleepHours: Double {
        asleepDuration / 3600.0
    }
}
