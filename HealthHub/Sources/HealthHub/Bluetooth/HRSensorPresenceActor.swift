//
//  HRSensorPresenceActor.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/07/2026.
//

import Foundation

/// Multicast broadcaster for HR-sensor presence: `true` when at least one HR
/// sensor is connected to the system, `false` otherwise. Emitted on every
/// CoreBluetooth connect / disconnect / connect-failure.
///
/// Each `newStream()` caller gets its own continuation. A stored single stream
/// would go silent for a second subscriber after a TCA effect restart / view
/// remount — the project's AsyncStream multicast rule.
actor HRSensorPresenceActor {

    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    /// `initial` is yielded immediately so a subscriber that attaches while a
    /// sensor is ALREADY connected sees the truth without waiting for an event.
    func newStream(initial: Bool) -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(initial)
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.remove(id) }
            }
        }
    }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }

    func broadcast(_ isConnected: Bool) {
        for continuation in continuations.values {
            continuation.yield(isConnected)
        }
    }
}
