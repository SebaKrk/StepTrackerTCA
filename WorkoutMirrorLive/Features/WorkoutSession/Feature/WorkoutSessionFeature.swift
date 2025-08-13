//
//  WorkoutSessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WorkoutSessionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.workoutSessionClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .workoutViewStateChange(viewState):
                state.workoutSessionState = viewState
                return .none
                
            case let .setWorkoutActivityType(workoutActivityType):
                return .run { send in
                    try await self.client.selectedWorkout(workoutActivityType.hkType)
                    //await send(.workoutStart)
                }
                
            case .prepareWorkout:
                return .run { send in
                    await send(.workoutViewStateChange(.countdown))
                }
                
            case .endingWorkout:
                return .run { send in
                    await send(.workoutViewStateChange(.summary))
                }
                
                // MARK: - View Action
            case let .view(.changeViewState(viewState)):
                return .send(.workoutViewStateChange(viewState))
                
            case .view(.viewDidAppear):
                if let workout = state.selectedWorkout {
                    return .run { send in
                        await send(.setWorkoutActivityType(workout))
                        await send(.prepareWorkout)
                    }
                }
                return .none
                
                // MARK: - Child
            case .countDown(.closeView):
                return .send(.workoutViewStateChange(.session))
                
            case .mirroring(.view(.pauseWorkoutButtonTaped)):
                return .run { send in
                    await self.client.togglePause()
                }
            case .mirroring(.view(.resumeWorkoutButtonTapped)):
                return .run { send in
                    await self.client.togglePause()
                }
            case .mirroring(.view(.endWorkoutButtonTapped)):
                return .run { send in
                    await self.client.endWorkout()
                    await send(.endingWorkout)
                }
                
                
            default:
                return .none
            }
        }
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.mirroring, action: \.mirroring) {
            WorkoutMirroringFeature()
        }
        Scope(state: \.summary, action: \.summary) {
            WorkoutSummaryFeature()
        }
    }
}

/// Implementation of `WorkoutSessionFeature` action
extension WorkoutSessionFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        case workoutViewStateChange(WorkoutSessionState)
        
        ///
        case setWorkoutActivityType(WorkoutType)
        
        ///
        case prepareWorkout
        
        ///
        case endingWorkout

        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case changeViewState(WorkoutSessionState)
        }
        
        // MARK: - Child
        
        ///
        case countDown(CountDownFeature.Action)
        
        ///
        case mirroring(WorkoutMirroringFeature.Action)
        
        ///
        case summary(WorkoutSummaryFeature.Action)
    }
    
    
}

/// Implementation of `WorkoutSessionFeature` state
extension WorkoutSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutSessionState: WorkoutSessionState = .start
        
        ///
        var selectedWorkout: WorkoutType?
        
        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()
        
        ///
        var mirroring: WorkoutMirroringFeature.State = .init()
        
        ///
        var summary: WorkoutSummaryFeature.State = .init()
    }
    
}

