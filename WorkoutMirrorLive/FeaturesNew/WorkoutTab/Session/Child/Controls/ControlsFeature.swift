//
//  ControlsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct ControlsFeature {
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .setWorkoutType(value):
                state.selectedWorkout = value
                return .none
                
            case .expandContainer:
                state.isExpanded.toggle()
                return .none
                
            case .lockView:
                state.isLocked.toggle()
                state.isExpanded = false
                return .none
                
            case let .sessionStateChange(value):
                state.sessionState = value
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.expandButtonTapped):
                return .send(.expandContainer)
                
            case .view(.lockButtonTapped):
                return .send(.lockView)
                
            case .view(.unlockConfirmed):
                state.isLocked = false
                return .none
              
            case .view(.mainControlButtonTapped):
                let newState: WorkoutSessionStateTest =
                    state.sessionState == .running ? .paused : .running
                return .send(.sessionStateChange(newState))
//            case let .view(.pauseWorkoutButtonTaped(value)):
//                return .run { send in
//                    await send(.sessionStateChange(.paused))
//                    print("wyslij do menagera: \(value)")
//                }
//                
//            case let .view(.resumeWorkoutButtonTapped(value)):
//                return .run { send in
//                    await send(.sessionStateChange(.running))
//                    print("wyslij do menagera: \(value)")
//                }
                
            case .view(.endWorkoutButtonTapped):
                print("endWorkoutButtonTapped")
                return .none
            }
        }
    }
    
}

/// Implementation of `ControlsFeature` action
extension ControlsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case setWorkoutType(WorkoutType)
        
        ///
        case sessionStateChange(WorkoutSessionStateTest)
        
        ///
        case expandContainer
        
        ///
        case lockView
        
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case expandButtonTapped
            
            ///
            case lockButtonTapped
            
            ///
            case unlockConfirmed
            
            ///
            case mainControlButtonTapped
            
            ///
            case endWorkoutButtonTapped
        }
    }
}

/// Implementation of `ControlsFeature` state
extension ControlsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var selectedWorkout: WorkoutType? = nil
        
        ///
        var sessionState: WorkoutSessionStateTest = .running
        
        ///
        var elapsedTime: TimeInterval = 0
        
        ///
        var isExpanded = false
        
        ///
        var isLocked = false
    }
    
}
