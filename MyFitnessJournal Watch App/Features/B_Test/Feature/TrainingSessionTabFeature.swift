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
                            print("metric: \(metric)")
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
        
        ///
        case setWorkoutActivityType(HKWorkoutActivityType)
        
        ///
        case workoutSessionIsRunningChanged(Bool)
        
        ///
        case cancelEffect
        
        ///
        case workoutStart
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case changeTab
        }
        
        // MARK: - Child Actions
        
        ///
        case controls(TrainingControlsFeature.Action)
        
        ///
        case metric(TrainingMetricFeature.Action)
    }
    
}

/// Implementation of `TrainingSessionTabFeature` state
extension TrainingSessionTabFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var selectedWorkout: HKWorkoutActivityType?
        
        ///
        var workoutSessionIsRunning: Bool = false
        
        ///
        var selectedTab: WorkoutSessionScreenAW = .workout
        
        ///
        var elapsedTime: TimeInterval = 0
        
        // MARK: - Child State
        
        ///
        var controls: TrainingControlsFeature.State {
            get {
                .init(sessionIsRunning: workoutSessionIsRunning)
            }
            set {
                workoutSessionIsRunning = newValue.sessionIsRunning
            }
        }
        
        ///
        var metric = TrainingMetricFeature.State()
    }
    
}

private enum CancelId: Hashable {
    case cancelSessionRunning
    case cancelMetrics
}


// Client
// SessionService
//  var selectedWorkout: HKWorkoutActivityType?

// MetricService
//var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
//    workoutManager.workoutMetricsStream
//}

// contorls
//var workoutSessionIsRunning: Bool {
//    workoutManager.workoutSessionIsRunning
//}

//
//func endWorkout() {
//    workoutManager.endWorkout()
//}
