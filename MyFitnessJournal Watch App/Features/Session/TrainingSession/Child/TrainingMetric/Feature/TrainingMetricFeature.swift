//
//  TrainingMetricFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct TrainingMetricFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingSessionClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .workoutMetrics(data):
                    state.workoutMetrics = data
                    return .none
                    
                case .hearAnimation:
                    if state.workoutMetrics.heartRate != 0 {
                        return .send(.toggleHeartAnimation(true))
                    } else {
                        return .send(.toggleHeartAnimation(false))
                    }
                    
                case let .toggleHeartAnimation(value):
                    state.animateHeart = value
                    return .none
                    
                case let .pauseChanged(paused):
                    state.isPaused = paused
                    if paused {
                        state.pausedElapsedTime = state.elapsedTime
                    }
                    return .none

                case .task:
                    return .run { send in
                        for await isRunning in client.workoutSessionIsRunningStream() {
                            await send(.pauseChanged(!isRunning))
                        }
                    }
                    
                    // MARK: - View Action
                    
                case let .view(.updateElapsedTime(date)):
                    guard !state.isPaused else {
                        state.elapsedTime = state.pausedElapsedTime
                        return .none
                    }
                    state.elapsedTime = client.elapsedTimeAt(date)
                    return .none
                }
            }
        }
    }
}


/// Implementation of `TrainingMetricFeature` state
extension TrainingMetricFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Updates the current workout metrics with new data.
        ///
        /// - Parameter data: The latest workout metrics from the session.
        case workoutMetrics(WorkoutMetrics)
        
        /// Triggers the heart animation logic based on heart rate availability.
        case hearAnimation
        
        /// Sets the heart animation state.
        ///
        /// - Parameter value: A Boolean indicating whether the heart should animate.
        case toggleHeartAnimation(Bool)
        
        /// Updates the paused state of the workout.
        ///
        /// - Parameter paused: A Boolean indicating whether the workout is paused.
        case pauseChanged(Bool)
        
        /// Starts a background task that observes workout session running state.
        case task
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            /// Called periodically to update the elapsed workout time.
            ///
            /// - Parameter date: The current timestamp used to calculate elapsed time.
            case updateElapsedTime(Date)
        }
    }
    
}

/// Implementation of `TrainingMetricFeature` state
extension TrainingMetricFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// The total duration of the workout session, updated in real time.
        var elapsedTime: TimeInterval = 0

        /// The elapsed workout time recorded at the moment the session was paused.
        var pausedElapsedTime: TimeInterval = 0

        /// Indicates whether the heart animation should be active based on heart rate.
        var animateHeart: Bool = false

        /// A Boolean value that determines whether the workout session is currently paused.
        var isPaused: Bool = false

        /// The current metrics of the workout, such as heart rate and active energy burned.
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
    }
    
}
