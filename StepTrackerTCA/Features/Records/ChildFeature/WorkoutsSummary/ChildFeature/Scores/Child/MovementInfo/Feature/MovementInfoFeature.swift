//
//  MovementInfoFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MovementInfoFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .fetchMovementInfo(movementString):
                
                if let crossMovement = CrossMovement.from(rawValue: movementString) {
                    state.currentMovement = .cross(crossMovement)
                } else if let fitnessMovement = FitnessMovement.from(rawValue: movementString) {
                    state.currentMovement = .fitness(fitnessMovement)
                } else if let strengthMovement = StrengthMovement.from(rawValue: movementString) {
                    state.currentMovement = .strength(strengthMovement)
                } else if let heroMovement = HeroMovement.from(rawValue: movementString) {
                    state.currentMovement = .hero(heroMovement)
                } else if let weightliftingMovement = WeightliftingMovement.from(rawValue: movementString) {
                    state.currentMovement = .weightlifting(weightliftingMovement)
                } else {
                    print("Movement not found for string: \(movementString)")
                    state.currentMovement = nil
                }
                
                return .none
                
            case .view(.viewDidAppear):
                return .run { [movement = state.movement] send in
                    await send(.fetchMovementInfo(movement))
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementInfoFeature` action
extension MovementInfoFeature {
    
    @CasePathable
    enum Action: ViewAction {
        case fetchMovementInfo(String)
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementInfoFeature` state
extension MovementInfoFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The name of the movement to be processed or displayed.
        /// This is passed as a string from external features and used to identify
        /// which specific movement is being referred to (e.g., "Snatch", "CleanAndJerk").
        let movement: String
        
        /// Holds the current movement after it has been processed by the reducer.
        /// It is an optional enum of type `Movement` that can be one of:
        /// - `CrossMovement`
        /// - `FitnessMovement`
        /// - `StrengthMovement`
        /// - `HeroMovement`
        /// - `WeightliftingMovement`
        ///
        /// If the movement string does not match any of the known cases, this will be `nil`.
        var currentMovement: Movement?
    }
    
}
