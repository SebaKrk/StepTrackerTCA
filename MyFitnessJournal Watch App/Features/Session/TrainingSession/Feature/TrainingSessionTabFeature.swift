//
//  TrainingSessionTabFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

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
                
            case .prepareWorkout:
                return .run { send in
                    await send(.showCountDown)
                }
                
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
                        await send(.prepareWorkout)
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
            
            case .showCountDown:
                print(state.selectedWorkout.debugDescription)
                state.destination = .countDown(CountDownFeature.State(selectedWorkout: state.selectedWorkout))
                //selectedWorkout
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        Scope(state: \.controls, action: \.controls) {
            TrainingControlsFeature()
        }
        Scope(state: \.metric, action: \.metric) {
            TrainingMetricFeature()
        }
    }
    
}
