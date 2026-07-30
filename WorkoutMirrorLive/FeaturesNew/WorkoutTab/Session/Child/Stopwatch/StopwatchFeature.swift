//
//  StopwatchFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation

/// A feature responsible for managing a stopwatch with start, stop, reset, and tick functionality.
/// It operates independently and communicates state changes via delegate actions.
@Reducer
struct StopwatchFeature {

    // MARK: - Properties

    /// Unique identifier used to namespace cancel IDs so multiple instances in one Store don't collide.
    let instanceID: AnyHashable

    init(id: some Hashable) {
        self.instanceID = AnyHashable(id)
    }

    // MARK: - Dependencies

    /// The clock dependency used for precise timing.
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View Actions

            case .view(.toggleVisibility):
                state.isVisible.toggle()
                return .send(.delegate(.didToggleVisibility))

            case let .view(.setVisibility(isVisible)):
                // Change only if difference exists
                guard state.isVisible != isVisible else { return .none }
                state.isVisible = isVisible
                return .send(.delegate(.didToggleVisibility))

            case .view(.start):
                // Prevent starting if already running
                guard !state.isRunning else { return .none }
                state.isRunning = true

                // Start a long-running effect (timer)
                return .merge(
                    .run { send in
                        // Tick every 10 milliseconds (0.01s)
                        for await _ in clock.timer(interval: .milliseconds(10)) {
                            await send(.internal(.tick))
                        }
                    }.cancellable(id: CancelID.timer(instanceID)),
                    .send(.delegate(.didStart))
                )

            case .view(.stop):
                guard state.isRunning else { return .none }
                state.isRunning = false

                // Cancel the timer effect and notify delegate
                return .merge(
                    .cancel(id: CancelID.timer(instanceID)),
                    .send(.delegate(.didStop))
                )

            case .view(.reset):
                state.time = 0
                return .send(.delegate(.didReset))

            case .view(.returnToPhaseTimerTapped):
                return .send(.delegate(.returnToPhaseTimerRequested))

            // MARK: - Internal Actions

            case .internal(.tick):
                state.time += 0.01
                return .none

            // MARK: - Delegate Actions

            case .delegate:
                return .none
            }
        }
    }
}
