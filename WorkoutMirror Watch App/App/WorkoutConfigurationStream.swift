//
//  WorkoutConfigurationStream.swift
//  WorkoutMirror Watch App
//

import Foundation
import HealthKit

/// Bridges `WKApplicationDelegate.handle(_ workoutConfiguration:)` to an `AsyncStream`
/// that `AppFeatureAW` can consume as a TCA effect.
///
/// The delegate method fires synchronously on the main thread, potentially before
/// the SwiftUI App's `WindowGroup` has been rendered. The singleton + lazy stream
/// pattern guarantees the continuation is ready whenever the first yield arrives.
final class WorkoutConfigurationStream: @unchecked Sendable {

    /// The slice of `HKWorkoutConfiguration` the app acts on. The configuration
    /// object itself is not Sendable, so it is narrowed at the delegate —
    /// `locationType` must ride along because `.running` alone cannot tell an
    /// outdoor run from a treadmill.
    struct Payload: Equatable, Sendable {
        let activityType: HKWorkoutActivityType
        let locationType: HKWorkoutSessionLocationType
    }

    static let shared = WorkoutConfigurationStream()

    private var continuation: AsyncStream<Payload>.Continuation?

    /// Subscribe once from `AppFeatureAW.view(.onAppear)`.
    let stream: AsyncStream<Payload>

    private init() {
        var cont: AsyncStream<Payload>.Continuation?
        stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont = $0 }
        continuation = cont
    }

    func yield(_ payload: Payload) {
        continuation?.yield(payload)
    }
}
