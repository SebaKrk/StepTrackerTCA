//
//  CountDownFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// A feature responsible for managing the countdown timer before a workout session starts.
/// It visualizes the remaining time and triggers the workout start upon completion.
@Reducer
struct CountDownFeature {

    // MARK: - Dependencies

    @Dependency(\.countDownClient) var client
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            // MARK: - Internal

            case .startCountDown:
                state.duration = state.duration
                state.timeRemaining = state.duration
                state.endDate = date().addingTimeInterval(state.duration)
                state.isActive = true

                return .merge(
                    // Cancel pulse timer when leaving the waiting phase for the countdown.
                    .cancel(id: CancelID.pulseTimer),
                    .run { send in
                        for await _ in await clock.timer(interval: .milliseconds(100)) {
                            await send(.timerTick)
                        }
                    }
                )

            case .timerTick:
                guard let endDate = state.endDate else {
                    return .none
                }

                let remainingTime = endDate.timeIntervalSince(date())

                if remainingTime > 0 {
                    state.timeRemaining = remainingTime
                    return .none
                } else {
                    return .concatenate(
                        .send(.endCountDown),
                        .send(.timerFinished)
                    )
                }

            case .endCountDown:
                state.isActive = false
                state.timeRemaining = 0
                state.endDate = nil
                return .none

            case .timerFinished:
                state.timerFinished = true
                return .send(.startWorkout)

            case .startWorkout:
                return .merge(
                    .send(.closeView),
                    .run { _ in await client.startWorkout() }
                )

            // MARK: - View Actions

            case .onAppear:
                // Dual-mode: only start the timer when we're already in `.countingDown`.
                // In `.waitingForWatch` the view sits idle until SessionFeature flips phase
                // and explicitly dispatches `.startCountDown` after mirroredSessionStartedStream fires.
                // In `.waitingForWatch` instead run the pulse timer for subtle ring opacity animation.
                guard state.phase == .countingDown else {
                    return .run { [clock] send in
                        for await _ in clock.timer(interval: .milliseconds(600)) {
                            await send(.pulseToggled)
                        }
                    }
                    .cancellable(id: CancelID.pulseTimer, cancelInFlight: true)
                }
                return .send(.startCountDown)

            case .pulseToggled:
                state.pulse.toggle()
                return .none

            case .closeView:
                /// Handled by parent feature (SessionFeature) or dismiss dependency if needed.
                return .none
            }
        }
    }
}
