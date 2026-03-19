//
//  PhasePanelFeature+State.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import SharedModels

/// Implementation of `PhasePanelFeature` state.
extension PhasePanelFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Ordered phases derived from the associated `TrainingSession`.
        var phases: [WorkoutPhase]

        /// Index of the phase currently displayed in the panel.
        var currentIndex: Int = 0

        /// Seconds elapsed since the current phase timer started.
        var elapsedSeconds: Int = 0

        /// Whether the phase timer is actively ticking.
        /// Set to `false` to pause the timer without navigating away.
        var timerRunning: Bool = true

        /// Set by the parent when the user stopwatch is open — disables the timer button.
        var isTimerButtonDisabled: Bool = false

        // MARK: - Computed

        /// The phase currently displayed in the panel.
        var currentPhase: WorkoutPhase { phases[currentIndex] }

        /// Total number of phases in the plan.
        var phaseCount: Int { phases.count }

        /// Value shown on the timer label.
        ///
        /// Counts down from `timeCap` in countdown mode,
        /// or counts up in stopwatch mode (when `timeCap` is `nil`).
        var timerDisplay: Int {
            guard let cap = currentPhase.timeCap else { return elapsedSeconds }
            return max(0, cap - elapsedSeconds)
        }

        /// `true` when the current phase has a `timeCap` and the timer counts down.
        var isCountdown: Bool { currentPhase.timeCap != nil }

        /// `true` when there is a next phase available to navigate to.
        var canGoNext: Bool { currentIndex < phases.count - 1 }

        /// `true` when there is a previous phase available to navigate back to.
        var canGoPrevious: Bool { currentIndex > 0 }

    }

}
