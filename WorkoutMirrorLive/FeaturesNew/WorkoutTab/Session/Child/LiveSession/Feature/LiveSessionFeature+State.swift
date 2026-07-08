//
//  LiveSessionFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `LiveSessionFeature` state
extension LiveSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The current metrics of the workout, such as heart rate and active energy burned.
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
        /// The currently calculated heart rate zone for the user, based on HR max and current HR.
        var currentHeartRateZone: HeartRateZone = .resting

        /// The user's current heart rate as a percentage of the maximum heart rate.
        var currentHeartRatePercentage: Int = 0

        /// The average heart rate calculated across the current session.
        var sessionAverageHeartRate: Int = 0

        /// The maximum heart rate recorded so far in the current session.
        var sessionMaxHeartRate: Int = 0

        /// The maximum heart rate (HR max) calculated at the beginning of the session.
        /// Provided by `SessionFeature`, which retrieves the user’s age and biological sex
        /// from HealthKit and resolves max HR via `maxHeartRateClient.fromAge(age, sex)`.
        var maxHeartRate: Int = 0

        /// Live effort points counter (Myzone-style) — credits time in HR zones
        /// as metrics arrive. HR-based by design: rest between sets still earns
        /// points for whatever zone the heart actually is in. Fresh per session
        /// (State is recreated). This IS the source of truth: its value is frozen
        /// into `PendingEffortScore` at session end and persisted as-is — not
        /// recomputed from HealthKit.
        var effortPoints = EffortPointsAccumulator()

        /// Mirroring-link status forwarded by `SessionFeature` (IOS-00098-G). Included
        /// in every Live Activity `ContentState` so Dynamic Island / Lock Screen can
        /// flag stale metrics while the Watch link is down.
        var isWatchConnectionLost: Bool = false
        
        // MARK: - Child

        /// Live Activity management (delegated to child reducer)
        var liveActivity = LiveActivityFeature.State()

        /// Independent user stopwatch (toolbar button).
        var userStopwatch = StopwatchFeature.State()

        /// Stopwatch managing the active plan phase timer.
        var phaseStopwatch = StopwatchFeature.State()

        // MARK: - Phase Panel

        /// Phase panel state. Non-nil only when the workout has an associated training plan.
        var phasePanel: PhasePanelFeature.State? = nil
        
        // MARK: - HR Buffer

        /// Single HR reading with timestamp — used to calculate per-phase HR at save time.
        struct HRSample: Sendable {
            let date: Date
            let bpm: Double
        }

        /// Append-only buffer of HR samples collected during the workout.
        /// ~720 samples per 60 min (one every ~5s) ≈ 12 KB. Cleared on session end.
        var hrBuffer: [HRSample] = []

        // MARK: - Helpers
        
        /// Creates Timer Activity Content State from current state
        var timerContentState: TimerActivityAttributes.ContentState {
            let adjustedStart = Date().addingTimeInterval(-userStopwatch.time)
            return TimerActivityAttributes.ContentState(
                heartRate: workoutMetrics.heartRate,
                heartRateZone: currentHeartRateZone,
                heartRatePercentage: currentHeartRatePercentage,
                elapsedTime: userStopwatch.time,
                isRunning: userStopwatch.isRunning,
                adjustedStartDate: adjustedStart,
                pauseDate: userStopwatch.isRunning ? nil : Date()
            )
        }
        
        /// Creates Workout Activity Content State from current state
        var workoutContentState: WorkoutSessionActivityAttributes.ContentState {
            WorkoutSessionActivityAttributes.ContentState(
                heartRate: workoutMetrics.heartRate,
                heartRateZone: currentHeartRateZone,
                heartRatePercentage: currentHeartRatePercentage,
                activeEnergy: workoutMetrics.activeEnergy,
                maxHeartRate: sessionMaxHeartRate,
                averageHeartRate: sessionAverageHeartRate,
                isWatchConnectionLost: isWatchConnectionLost
            )
        }
    }
    
}
