//
//  CountDownFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension CountDownFeature {

    /// Visual + behavioral phase of the countdown view.
    /// - `.waitingForWatch`: gray empty ring + activity icon + "Rozpoczynam na Apple Watch" text. No timer.
    /// - `.countingDown`: existing 3-2-1 countdown with progress ring.
    enum CountDownPhase: Equatable, Sendable {
        case waitingForWatch
        case countingDown
    }

    @ObservableState
    struct State: Equatable {

        /// AI-classified workout type set when the user starts a plan. Drives the
        /// header icon + label shown above the countdown ring.
        /// Nil for ad-hoc workouts started without a plan (header hidden).
        var workoutType: WorkoutActivityType?

        /// Drives the dual-mode render. Default `.countingDown` keeps iPhone-standalone flow unchanged.
        /// Watch-primary `viewDidAppear` switches this to `.waitingForWatch` before launching Watch.
        var phase: CountDownPhase = .countingDown

        /// Pulse animation phase for the `.waitingForWatch` ring opacity.
        /// Toggled by `pulseToggled` every 600ms while in the waiting phase.
        var pulse: Bool = false

        /// Current time remaining in seconds.
        var timeRemaining: TimeInterval = 3

        /// Total duration of the countdown in seconds.
        var duration: TimeInterval = 3

        /// Indicates if the countdown is currently active.
        var isActive: Bool = false

        /// The calculated end date of the countdown.
        var endDate: Date?

        /// Flag indicating if the timer has finished.
        var timerFinished: Bool = false

        /// Calculated trim value for the circular progress view (0.0 to 1.0).
        var trimValue: Double {
            timeRemaining > 0 ? timeRemaining / duration : 0
        }

        /// Helper to determine if we are in the initial setup state.
        var isSettingTrim: Bool {
            timeRemaining == duration
        }
    }

}
