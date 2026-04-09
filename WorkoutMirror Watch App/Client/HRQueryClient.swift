//
//  HRQueryClient.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import HealthKit

/// TCA dependency that reads live heart rate data from the Apple Watch sensor
/// without starting an `HKWorkoutSession`.
///
/// Uses `HKAnchoredObjectQuery` with an `updateHandler` to deliver continuous
/// BPM readings via an `AsyncStream<Double>`.
///
/// - Note: Without an active `HKWorkoutSession`, watchOS samples HR less frequently
///   (~1/min at rest). Frequency increases automatically during movement.
struct HRQueryClient {

    /// Starts the heart rate query and returns a stream of BPM readings.
    var startQuery: @Sendable () -> AsyncStream<Double>

    /// Stops the active heart rate query and finishes the stream.
    var stopQuery: @Sendable () -> Void
}

// MARK: - Dependency Registration

extension DependencyValues {
    var hrQueryClient: HRQueryClient {
        get { self[HRQueryClientKey.self] }
        set { self[HRQueryClientKey.self] = newValue }
    }
}

private enum HRQueryClientKey: DependencyKey {
    static let liveValue: HRQueryClient = {
        let holder = HRQueryHolder()
        return HRQueryClient {
            holder.startQuery()
        } stopQuery: {
            holder.stopQuery()
        }
    }()
}

// MARK: - HRQueryHolder

/// Manages the lifecycle of an `HKAnchoredObjectQuery` and the `AsyncStream` continuation.
private final class HRQueryHolder: @unchecked Sendable {

    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?
    private var continuation: AsyncStream<Double>.Continuation?

    /// Starts the anchored HR query and returns a live BPM stream.
    func startQuery() -> AsyncStream<Double> {
        let (stream, continuation) = AsyncStream<Double>.makeStream()
        self.continuation = continuation

        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            continuation.finish()
            return stream
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }

        self.query = query
        healthStore.execute(query)
        return stream
    }

    /// Stops the query and finishes the stream.
    func stopQuery() {
        if let query {
            healthStore.stop(query)
            self.query = nil
        }
        continuation?.finish()
        continuation = nil
    }

    private func handleSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        for sample in samples {
            let bpm = sample.quantity.doubleValue(for: unit)
            continuation?.yield(bpm)
        }
    }
}
