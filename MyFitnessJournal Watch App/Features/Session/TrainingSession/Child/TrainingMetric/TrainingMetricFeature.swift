//
//  TrainingMetricFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Foundation

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
                    // Zapisz czas gdy trening jest wstrzymany
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
                    // Tylko aktualizuj czas gdy trening NIE jest wstrzymany
                    guard !state.isPaused else {
                        // Gdy jest wstrzymany, utrzymuj ostatni zapisany czas
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
        
        case workoutMetrics(WorkoutMetrics)
        
        case hearAnimation
        
        case toggleHeartAnimation(Bool)
        
        case pauseChanged(Bool)
        
        case task
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            case updateElapsedTime(Date)
        }
    }
    
}

/// Implementation of `TrainingMetricFeature` state
extension TrainingMetricFeature {
    @ObservableState
    struct State: Equatable {
        
        var elapsedTime: TimeInterval = 0
        
        var pausedElapsedTime: TimeInterval = 0
        
        var animateHeart: Bool = false
        
        var isPaused: Bool = false
        
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
    }
    
}
