//
//  TrainingSessionTabFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

@Reducer
struct TrainingSessionTabFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingSessionClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
            case let .tabChanged(tabItem):
                state.selectedTab = tabItem
                return .none
                
            case let .setWorkoutActivityType(workoutActivityType):
                return .run { send in
                    try await self.client.selectedWorkout(workoutActivityType)
                    await send(.workoutStart)
                }
                
            case let .workoutSessionIsRunningChanged(isRunning):
                state.workoutSessionIsRunning = isRunning
                return .none
                
            case .cancelEffect:
                return .merge(
                    .cancel(id: CancelId.cancelSessionRunning),
                    .cancel(id: CancelId.cancelMetrics)
                )
                
            case .workoutStart:
                return .merge(
                    .run { send in
                        for await isRunning in self.client.workoutSessionIsRunningStream() {
                            await send(.workoutSessionIsRunningChanged(isRunning))
                        }
                    }.cancellable(id: CancelId.cancelSessionRunning),
                    .run { send in
                        for await metric in self.client.workoutMetricsStream() {
                            await send(.metric(.workoutMetrics(metric)))
                        }
                    }.cancellable(id: CancelId.cancelMetrics)
                )
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                if let workout = state.selectedWorkout {
                    return .run { send in
                        await send(.setWorkoutActivityType(workout))
                    }
                }
                return .none
                
            case .view(.changeTab):
                state.selectedTab = .workout
                return .none
                
                // MARK: - Child Action
            case .controls(.view(.endButtonPressed)):
                return .concatenate(
                    .run { send in
                        await self.client.endWorkout()
                    },
                    .run { send in
                        await send(.cancelEffect)
                    }
                )
                
            case .controls(.view(.togglePauseButtonPressed)):
                return .run { send in
                    await self.client.togglePause()
                }
                
            case .metric(_):
                return .none
            }
        }
        Scope(state: \.controls, action: \.controls) {
            TrainingControlsFeature()
        }
        Scope(state: \.metric, action: \.metric) {
            TrainingMetricFeature()
        }
    }
}


/// Implementation of `TrainingSessionTabFeature` action
extension TrainingSessionTabFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(WorkoutSessionScreenAW)
        
        /// Sets the selected workout activity type and triggers workout start.
        case setWorkoutActivityType(HKWorkoutActivityType)
        
        /// Updates the state to reflect whether the workout session is running.
        ///
        /// - Parameter isRunning: Boolean indicating the running state.
        case workoutSessionIsRunningChanged(Bool)
        
        /// Cancels active effects such as metrics or session monitoring streams.
        case cancelEffect
        
        /// Starts the workout session, including monitoring streams for session status and metrics.
        case workoutStart
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Triggered when the view appears, used to initialize workout setup.
            case viewDidAppear
            
            /// User-triggered tab change to the workout screen.
            case changeTab
        }
        
        // MARK: - Child Actions
        
        /// Delegate action for training controls.
        case controls(TrainingControlsFeature.Action)
        
        /// Delegate action for workout metrics.
        case metric(TrainingMetricFeature.Action)
    }
    
}

/// Implementation of `TrainingSessionTabFeature` state
extension TrainingSessionTabFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The currently selected workout activity type, e.g., running, cycling.
        var selectedWorkout: HKWorkoutActivityType?
        
        /// Indicates whether the workout session is currently running.
        var workoutSessionIsRunning: Bool = false
        
        /// The currently selected tab in the workout session interface.
        var selectedTab: WorkoutSessionScreenAW = .workout
        
        /// The elapsed workout time used for tracking duration.
        var elapsedTime: TimeInterval = 0
        
        // MARK: - Child State
        
        /// State for managing the training control buttons and pause/resume status.
        var controls: TrainingControlsFeature.State {
            get {
                .init(sessionIsRunning: workoutSessionIsRunning)
            }
            set {
                workoutSessionIsRunning = newValue.sessionIsRunning
            }
        }
        
        /// State for displaying and managing real-time workout metrics.
        var metric = TrainingMetricFeature.State()
    }
    
}

/// Identifiers for cancellable effects used in the workout session feature.
///
/// These are used to manage long-running streams such as session state and metrics updates.
private enum CancelId: Hashable {
    /// Cancellation ID for the workout session running state stream.
    case cancelSessionRunning
    /// Cancellation ID for the workout metrics stream.
    case cancelMetrics
}
