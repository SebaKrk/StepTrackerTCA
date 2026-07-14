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

    /// Post-save mini-summary lifecycle (IOS-00098-D).
    ///
    /// `presented(nil)` means the workout was saved-attempted but `finishWorkout()`
    /// returned no workout (e.g. save failure) — the view shows a fallback message
    /// instead of metrics.
    enum SummaryPhase: Equatable {
        case hidden
        case presented(WatchWorkoutSummary?)
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

        /// Live effort points counter (Myzone-style) — credits time in HR zones
        /// as sensor samples arrive. DISPLAY-ONLY on the wrist: the persisted value
        /// is frozen from the iPhone's LiveSession accumulator at session end, not
        /// from here and not from HealthKit (small wrist-vs-phone drift is fine).
        /// Fresh per workout — `AppFeatureAW` creates a new `State` for every session.
        var effortPoints = EffortPointsAccumulator()

        /// Timestamp of the previous `hrReceived` sample — the credited duration
        /// for the current sample is the delta between the two.
        var lastEffortSampleDate: Date?

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

        // MARK: - Countdown (synced with iPhone)

        /// `true` while the pre-workout 3-2-1 countdown overlay is showing.
        /// Default `true` so Watch shows the countdown **immediately** on HRMirror appearance,
        /// before iPhone's countdownStart event arrives (avoids briefly flashing the workout
        /// view with stopwatch at 00:00). `.countdownStart` from iPhone restarts the timer
        /// (cancelInFlight) for defensive sync; cleared when local timer hits 0 or
        /// `.countdownFinished` arrives.
        var isCountingDown: Bool = true

        /// Remaining seconds in the 3-2-1 countdown overlay. Decremented every second
        /// by `.countdownTick`. Displayed as a large numeric overlay on the Watch screen.
        var countdownRemaining: Int = 3

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

        // MARK: - Saving

        /// `true` from `.stop` until `endSession()` + log transfer completes.
        ///
        /// While `true` a full-screen "Saving…" overlay is shown.
        var isSaving: Bool = false

        // MARK: - Summary

        /// Mini-summary shown after the workout is saved (IOS-00098-D).
        ///
        /// The Watch is the primary session owner, so it presents the immediate
        /// summary from the `finishWorkout()` return value; detailed results entry
        /// happens later on iPhone (History). Dismissed via the Done button, which
        /// triggers `.delegate(.didFinishSaving)`.
        var summaryPhase: SummaryPhase = .hidden

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
