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
    
    // MARK: - Dependencies
    
    /// The clock dependency used for precise timing.
    @Dependency(\.continuousClock) var clock
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        
        /// Determines if the stopwatch UI is currently visible.
        var isVisible: Bool = false
        
        /// The current elapsed time of the stopwatch in seconds.
        var time: TimeInterval = 0
        
        /// Indicates if the stopwatch is currently running (ticking).
        var isRunning: Bool = false

        /// True when the stopwatch is controlling the active phase timer (replaces phase panel timer).
        var isManagingPhase: Bool = false
    }
    
    // MARK: - Actions
    
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
            case didToggleVisibility(unexpected: Bool)

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
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - View Actions
                
            case .view(.toggleVisibility):
                state.isVisible.toggle()
                return .send(.delegate(.didToggleVisibility(unexpected: false)))
                
            case let .view(.setVisibility(isVisible)):
                // Change only if difference exists
                guard state.isVisible != isVisible else { return .none }
                state.isVisible = isVisible
                return .send(.delegate(.didToggleVisibility(unexpected: false)))
                
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
                    }.cancellable(id: "stopwatch-timer"),
                    .send(.delegate(.didStart))
                )
                
            case .view(.stop):
                guard state.isRunning else { return .none }
                state.isRunning = false
                
                // Cancel the timer effect and notify delegate
                return .merge(
                    .cancel(id: "stopwatch-timer"),
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
