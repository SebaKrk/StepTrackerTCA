//
//  ScoresFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ScoresFeature {
    
    // MARK: - Dependencies
    
    let services: ScoresFeatureServices
    
    // MARK: - Livecycle
    
    init(service: ScoresFeatureServices = DefaultScoresFeatureServices()) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                // MARK: - Action
                
            case .updateWorkout:
                let selectedWorkout = state.selectedWorkout
                state.bestResult = services.bestSession(from: selectedWorkout.movements.flatMap { $0.sessions })
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.updateWorkout)
                }
                
            case let .view(.openExerciseInfo(movement)):
                state.destination = .openInfo(MovementInfoFeature.State(movement: movement))
                return .none
                
            case let .view(.openMovementDetails(movement, sessions)):
                state.destination = .showDetails(MovementDetailsFeature.State(movement: movement, sessions: sessions))
                return .none
                
            case .view(.goalsButtonTapped):
                return .run { send in
                    await send(.openGoalsSheet)
                }
                
                // MARK: - Destination
                
              case .openGoalsSheet:
                  state.destination = .openGoal(SetEditGoalFeature.State())
                  return .none
                  
                
            case .destination:
                return .none
            }
        }
        
        .ifLet(\.$destination, action: \.destination)
    }
}










