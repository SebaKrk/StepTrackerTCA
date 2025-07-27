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
                
            case let .changePreviewWorkoutPlanStatus(value):
                state.seeWorkoutPlanPreview = value
                return .none
                
            case .workoutSchedulingResult(let result):
                if result {
                    print("Workout dodany do Apple Watch")
                } else {
                    print("Nie udało się dodać workout'u")
                }
                return .none

                // MARK: - View Actions
                
            case .view(.onAppear):
                let trainingSession = service.mapTrainingSessionToCustomWorkout(state.trainingSession)
                state.workoutPlan = WorkoutPlan(.custom(trainingSession!))
                return .none
                
            case .view(.showApplePreview):
                state.showPreview.toggle()
                return .send(.changePreviewWorkoutPlanStatus(true))
                
            case .view(.addToAppleWatch):
                guard let workoutPlan = state.workoutPlan else { return .none }
                return .run { send in
                    let result = await service.addScheduleAndCheck(workoutPlan: workoutPlan)
                    await send(.workoutSchedulingResult(result))
                }
                
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
        case changePreviewWorkoutPlanStatus(Bool)
        
        case workoutSchedulingResult(Bool)
        
        // MARK: - View actions
        case view(View)
        
        enum View {
            case onAppear
            case showApplePreview
            case addToAppleWatch
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
        var seeWorkoutPlanPreview: Bool = false
        
    }
    
}
