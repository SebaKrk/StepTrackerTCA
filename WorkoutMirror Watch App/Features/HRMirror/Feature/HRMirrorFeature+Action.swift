//
//  HRMirrorFeature+Action.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import Foundation

extension HRMirrorFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        /// Starts HR query, timers and extended runtime session.
        ///
        /// Sent by the parent (`AppFeatureAW`) immediately when `workoutStarted`
        /// is received — before `HRMirrorView` has had a chance to appear.
        /// This removes the SwiftUI render-cycle delay from the HR acquisition pipeline.
        case start

        /// Delivered when `HRQueryClient` yields a new BPM sample from the Watch sensor.
        ///
        /// Updates `heartRate`, recalculates `heartRateZone`, and forwards
        /// the reading to the paired iPhone via WatchConnectivity.
        case hrReceived(Double)

        /// Fired every 0.1 s for smooth centisecond display between iPhone ticks.
        ///
        /// Increments `elapsedSeconds` by 0.1 only when not paused.
        /// Overridden on every `workoutTick` from iPhone.
        case subSecondTick

        /// Fired 3 s after appear or last tap — hides the TabView indicator dots.
        case hideTabIndicator

        // MARK: - iPhone Events

        /// Received from the parent when the paired iPhone pauses the workout.
        case workoutPaused

        /// Received from the parent when the paired iPhone resumes the workout.
        ///
        /// Resets `elapsedSeconds` to the authoritative value from iPhone.
        case workoutResumed(elapsedSeconds: TimeInterval)

        /// Received once per second from iPhone — the authoritative elapsed time.
        ///
        /// Watch has no local timer; it displays exactly what iPhone sends.
        case workoutTick(elapsedSeconds: TimeInterval)

        // MARK: - View Actions

        /// Actions triggered directly by view lifecycle events.
        case view(ViewAction)

        // MARK: - Nested Types

        enum ViewAction {

            /// Called when `HRMirrorView` appears on screen.
            ///
            /// Starts the `HKAnchoredObjectQuery` heart rate stream
            /// and the one-second elapsed-time ticker.
            case onAppear

            /// Called when the user taps the pause/resume button on Watch.
            ///
            /// Toggles the paused state locally and forwards the corresponding
            /// `workoutPaused` or `workoutResumed` event to the paired iPhone.
            case pauseResumeTapped

            /// Called when the user taps anywhere on screen.
            ///
            /// Shows the TabView indicator dots and resets the 3 s auto-hide timer.
            case screenTapped

            /// Called when the user swipes to a different tab.
            case tabSelected(HRMirrorFeature.Tab)

        }

    }

}
