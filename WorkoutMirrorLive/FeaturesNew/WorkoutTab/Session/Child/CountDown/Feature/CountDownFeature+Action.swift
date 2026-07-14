//
//  CountDownFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture

extension CountDownFeature {

    enum Action {

        /// Triggered when the view appears. Stats the countdown sequence.
        case onAppear

        /// Internal action to initialize state and run the timer effect.
        case startCountDown

        /// Internal action to clean up state after countdown completes.
        case endCountDown

        /// Tick action triggered by the timer every 0.1s.
        case timerTick

        /// Triggered when the timer successfully reaches zero.
        case timerFinished

        /// Triggers the actual workout start via the client.
        case startWorkout

        /// Pulse timer tick (600 ms cadence). Toggles `state.pulse` to animate ring
        /// opacity in `.waitingForWatch` phase. Cancelled on `startCountDown`.
        case pulseToggled

        /// Action to signal view dismissal (usually handled by parent).
        case closeView
    }

}
