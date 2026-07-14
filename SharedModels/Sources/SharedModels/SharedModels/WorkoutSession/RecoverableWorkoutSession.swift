//
//  RecoverableWorkoutSession.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 30/05/2026.
//

import Foundation
import HealthKit

/// Marker protocol for `WorkoutSession` implementations that can be restored after a
/// host-process crash via `HKHealthStore.recoverActiveWorkoutSession()` (iOS 17+).
///
/// Per WWDC25 (`Build the next generation of Workouts`): only `.primary` sessions running
/// on iPhone require manual rebuild of `HKLiveWorkoutBuilder` and `HKLiveWorkoutDataSource`
/// after recovery — HealthKit returns the running session, but builder + dataSource references
/// die with the crashed process. `.mirroredFromRemoteDevice` sessions delegate builder ownership
/// to the paired Watch and do not require this hook, which is why the conformance is
/// iPhone-specific by design (Interface Segregation).
public protocol RecoverableWorkoutSession: WorkoutSession {

    /// Reattach to a session returned by `HKHealthStore.recoverActiveWorkoutSession()`.
    ///
    /// MUST NOT be paired with `prepare()` — the session is already past `.prepared`. The
    /// existing builder timeline survives in HealthKit; calling `beginCollection` again
    /// would reset the start timestamp and break sample continuity.
    func reattach(to recoveredSession: HKWorkoutSession) async throws
}
