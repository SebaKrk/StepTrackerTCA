//
//  ControlsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthKit

@Reducer
struct ControlsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.sessionClient) var client
    
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
                
            case let .sessionStateUpdated(value):
                state.sessionState = value
                if value == .paused {
                    state.isPaused = true
                    state.pausedElapsedTime = state.elapsedTime
                } else if value == .running {
                    state.isPaused = false
                }
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
                //recznie zmien sessionStateUpdated
                return .run { _ in
                    await client.togglePause()
                }
                
            case .view(.endWorkoutButtonTapped):
                // SessionFeature handles the full end sequence (WC event + endWorkout).
                // ControlsFeature must not call endWorkout() independently — doing so
                // would call session.end() twice (crash in iPhone-standalone mode).
                return .none
                
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

/// Implementation of `ControlsFeature` action
extension ControlsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case setWorkoutType(WorkoutType)
        
        ///
        case sessionStateUpdated(HKWorkoutSessionState)
        
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
            
            
            /// Called periodically to update the elapsed workout time.
            ///
            /// - Parameter date: The current timestamp used to calculate elapsed time.
            case updateElapsedTime(Date)
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
        //var sessionState: WorkoutSessionStateTest = .running
        var sessionState: HKWorkoutSessionState = .notStarted
        
        ///
        var elapsedTime: TimeInterval = 0
        
        ///
        var pausedElapsedTime: TimeInterval = 0
        
        ///
        var isPaused: Bool = false
        
        ///
        var isExpanded = false
        
        ///
        var isLocked = false
    }
    
}


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
                
