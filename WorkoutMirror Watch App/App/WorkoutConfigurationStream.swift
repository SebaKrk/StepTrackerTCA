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

    static let shared = WorkoutConfigurationStream()

    private var continuation: AsyncStream<HKWorkoutActivityType>.Continuation?

    /// Subscribe once from `AppFeatureAW.view(.onAppear)`.
    let stream: AsyncStream<HKWorkoutActivityType>

    private init() {
        var cont: AsyncStream<HKWorkoutActivityType>.Continuation?
        stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont = $0 }
        continuation = cont
    }

    func yield(_ activityType: HKWorkoutActivityType) {
        continuation?.yield(activityType)
    }
}
