//
//  HRMirrorFeature+State.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation
import HealthKit

extension HRMirrorFeature {

    enum Tab: Int, Hashable {
        case controls = 0
        case hr       = 1
        case music    = 2
    }

    @ObservableState
    struct State: Equatable {

        // MARK: - Heart Rate

        /// Most recent heart rate reading from the Watch sensor, in beats per minute.
        ///
        /// Starts at `0` until the first `HKAnchoredObjectQuery` sample arrives.
        var heartRate: Int = 0

        /// Heart rate zone derived from `heartRate` relative to `maxHeartRate`.
        ///
        /// Updated on every `hrReceived` action.
        var heartRateZone: HeartRateZone = .resting

        // MARK: - Workout Clock

        /// Elapsed workout time in seconds.
        ///
        /// Seeded from iPhone on `.workoutStarted` / `.workoutResumed` events
        /// so the Watch clock stays in sync with the phone even after pauses.
        var elapsedSeconds: TimeInterval

        /// Whether the workout is currently paused.
        ///
        /// When `true`, `elapsedTimeTick` actions are ignored so the counter freezes.
        var isPaused: Bool = false

        // MARK: - Configuration

        /// User's estimated maximum heart rate, used to calculate `heartRateZone`.
        ///
        /// Set to `0` until iPhone sends the value via `workoutStarted` or `maxHRUpdated`.
        var maxHeartRate: Int

        // MARK: - UI

        /// Active tab — defaults to `.hr` so the session view opens first.
        var selectedTab: Tab = .hr

        /// Whether the TabView page indicator dots are visible.
        ///
        /// Set to `true` on appear and on screen tap, then auto-hidden after 3 s.
        var showTabIndicator: Bool = true

        // MARK: - Workout Configuration

        /// Activity type of the current workout session.
        ///
        /// Passed from iPhone via `.workoutStarted` and used by
        /// `WatchWorkoutSessionClient` to create the correct `HKWorkoutConfiguration`.
        var activityType: HKWorkoutActivityType

        // MARK: - Lifecycle

        init(
            elapsedSeconds: TimeInterval = 0,
            maxHeartRate: Int = 0,
            activityType: HKWorkoutActivityType = HKWorkoutActivityType(rawValue: 37)! // .other
        ) {
            self.elapsedSeconds = elapsedSeconds
            self.maxHeartRate = maxHeartRate
            self.activityType = activityType
        }

    }

}
