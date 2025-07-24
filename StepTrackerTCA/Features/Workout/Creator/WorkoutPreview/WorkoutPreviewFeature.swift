//
//  WorkoutPreviewFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/07/2025.
//

import Foundation
import ComposableArchitecture
import WorkoutKit

@Reducer
struct WorkoutPreviewFeature {
    
    let service: DefaultWorkoutPreviewService
    
    init(service: DefaultWorkoutPreviewService = WorkoutPreviewService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Actions

                // MARK: - View Actions
                
            case .view(.onAppear):
                let trainingSession = service.mapTrainingSessionToCustomWorkout(state.trainingSession)
                state.workoutPlan = WorkoutPlan(.custom(trainingSession!))
                return .none
                
            case .view(.showApplePreview):
                state.showPreview.toggle()
                return .none
            }
        }
    }
    
}
// MARK: - Action

/// Implementation of `WorkoutPreviewFeature` action
extension WorkoutPreviewFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        case binding(BindingAction<State>)
        
        // MARK: - Actions

        // MARK: - View actions
        case view(View)
        
        enum View {
            case onAppear
            case showApplePreview
        }
    }
}

// MARK: - State

/// Implementation of `WorkoutPreview` state
extension WorkoutPreviewFeature {
    
    @ObservableState
    struct State {
        
        // MARK: Properties
        
        let trainingSession: TrainingSession
        var workoutPlan: WorkoutPlan? = nil
        var showPreview: Bool = false
        
    }
    
}
