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
            case .expandContainer:
                state.isExpanded.toggle()
                return .none
                
            case .lockView:
                state.isLocked = true
                return .none
                
            case .showLockView:
                state.isExpanded = true
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
                
            case let .view(.pauseWorkoutButtonTaped(value)):
                return .run { send in
                    await send(.sessionStateChange(.paused))
                    print("wyslij do menagera: \(value)")
                }
                
            case let .view(.resumeWorkoutButtonTapped(value)):
                return .run { send in
                    await send(.sessionStateChange(.running))
                    print("wyslij do menagera: \(value)")
                }
                
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
        case expandContainer
        
        ///
        case showLockView
        
        ///
        case lockView
        
        ///
        case sessionStateChange(WorkoutSessionStateTest)
        
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
            case pauseWorkoutButtonTaped(Bool)
            
            ///
            case resumeWorkoutButtonTapped(Bool)
            
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
        var elapsedTime: TimeInterval = 0
        
        ///
        var isExpanded = false
        
        ///
        var isLocked = false
        
        ///
        var sessionState: WorkoutSessionStateTest = .running
    }
    
}
