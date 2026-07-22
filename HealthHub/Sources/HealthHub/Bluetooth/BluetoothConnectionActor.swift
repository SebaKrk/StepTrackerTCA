//
//  BluetoothConnectionActor.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 22/07/2026.
//

import Foundation
import SharedModels

/// Multicast broadcaster for held HR-strap connection events: `nil` = connected /
/// cleared, a value = the reason the strap dropped.
///
/// Each `newStream()` caller gets its own continuation. A stored single stream
/// would go silent for a second subscriber after a TCA effect restart / view
/// remount — the project's AsyncStream multicast rule.
actor BluetoothConnectionActor {

    private var continuations: [UUID: AsyncStream<SensorDisconnectReason?>.Continuation] = [:]

    func newStream() -> AsyncStream<SensorDisconnectReason?> {
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

    func broadcast(_ reason: SensorDisconnectReason?) {
        for continuation in continuations.values {
            continuation.yield(reason)
        }
    }
}
