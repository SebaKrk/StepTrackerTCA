//
//  StrapHRReadingActor.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 30/07/2026.
//

import Foundation

/// A single heart-rate reading taken directly from the strap's GATT
/// notification — the app's own view of the sensor, independent of HealthKit.
public struct StrapHRReading: Sendable {
    public let bpm: Int
    public let date: Date

    public init(bpm: Int, date: Date) {
        self.bpm = bpm
        self.date = date
    }
}

/// Multicast broadcaster for strap GATT readings. Feeds the HR fallback in
/// `iPhoneWorkoutSession`: when HealthKit's pipeline stalls while the strap is
/// still sending, these readings substitute the frozen builder value.
///
/// Each `newStream()` caller gets its own continuation. A stored single stream
/// would go silent for a second subscriber after a TCA effect restart / view
/// remount — the project's AsyncStream multicast rule.
actor StrapHRReadingActor {

    private var continuations: [UUID: AsyncStream<StrapHRReading>.Continuation] = [:]

    func newStream() -> AsyncStream<StrapHRReading> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.remove(id) }
            }
        }
    }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }

    func broadcast(_ reading: StrapHRReading) {
        for continuation in continuations.values {
            continuation.yield(reading)
        }
    }
}
