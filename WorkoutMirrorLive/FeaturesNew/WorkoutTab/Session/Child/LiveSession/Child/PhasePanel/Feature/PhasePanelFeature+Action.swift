//
//  PhasePanelFeature+Action.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture

/// Implementation of `PhasePanelFeature` actions.
extension PhasePanelFeature {

    @CasePathable
    enum Action: ViewAction {

        /// View-triggered actions.
        case view(View)

        /// Internal timer tick — fires every second while `timerRunning` is `true`.
        /// Triggered by `.view(.appeared)` and self-schedules via a cancellable effect.
        case timerTick

        /// Delegate actions sent to the parent feature.
        case delegate(Delegate)

        // MARK: - View Actions

        enum View {

            /// Called when the panel appears on screen.
            /// Starts the per-phase timer.
            case appeared

            /// User tapped the button to advance to the next phase.
            /// Ignored when already on the last phase.
            case nextPhaseTapped

            /// User tapped the button to go back to the previous phase.
            /// Ignored when already on the first phase.
            case previousPhaseTapped

            /// User tapped the timer display — requests stopwatch to take over timer control.
            case timerTapped

        }

        // MARK: - Delegate Actions

        enum Delegate {

            /// Sent when user taps the timer — parent should show the stopwatch
            /// pre-seeded with the current elapsed time for manual control.
            case timerManagementRequested(elapsedSeconds: Int)

        }
    }

}
