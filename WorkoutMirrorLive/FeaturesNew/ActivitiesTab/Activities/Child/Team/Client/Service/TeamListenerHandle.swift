//
//  TeamListenerHandle.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import FirebaseFirestore
import Foundation

/// Owns one Firestore listener for the lifetime of a stream and drops results that arrive out of order.
nonisolated final class TeamListenerHandle: @unchecked Sendable {

    private let lock = NSLock()
    private var registration: (any ListenerRegistration)?
    private var isRemoved = false
    private var latestGeneration = 0

    /// Keeps the listener; removes it at once when the stream has already ended.
    func attach(_ listener: any ListenerRegistration) {
        lock.lock()
        defer { lock.unlock() }
        if isRemoved {
            listener.remove()
        } else {
            registration = listener
        }
    }

    /// Stops listening; safe to call more than once.
    func remove() {
        lock.lock()
        defer { lock.unlock() }
        isRemoved = true
        registration?.remove()
        registration = nil
    }

    /// Numbers each snapshot so a slow resolve of an older one cannot overwrite a newer result.
    func nextGeneration() -> Int {
        lock.lock()
        defer { lock.unlock() }
        latestGeneration += 1
        return latestGeneration
    }

    /// Whether `generation` is still the newest snapshot.
    func isLatest(_ generation: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generation == latestGeneration && !isRemoved
    }
}
