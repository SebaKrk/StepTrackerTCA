//
//  StopwatchFeature+Action.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture

extension StopwatchFeature {

    @CasePathable
    enum Action: ViewAction {

        /// Actions triggered by the user interface.
        case view(View)

        enum View: Equatable {
            /// Toggles the visibility of the stopwatch.
            case toggleVisibility

            /// Sets the visibility explicitly.
            case setVisibility(Bool)

            /// Starts the stopwatch timer.
            case start

            /// Stops the stopwatch timer.
            case stop

            /// Resets the stopwatch time to zero.
            case reset

            /// User tapped "Back to plan" — requests returning timer control to the phase panel.
            case returnToPhaseTimerTapped
        }

        /// Internal actions used by the reducer (e.g. timer ticks).
        case `internal`(Internal)

        enum Internal: Equatable {
            /// Triggered periodically when the stopwatch is running to update the time.
            case tick
        }

        /// Delegate actions to notify the parent feature about relevant events.
        case delegate(Delegate)

        enum Delegate: Equatable {
            /// Notifies parent that visibility has changed.
            case didToggleVisibility

            /// Notifies parent that the stopwatch has started.
            case didStart

            /// Notifies parent that the stopwatch has stopped.
            case didStop

            /// Notifies parent that the stopwatch has been reset.
            case didReset

            /// Notifies parent that user wants to return timer control to the phase panel.
            case returnToPhaseTimerRequested
        }
    }

}
