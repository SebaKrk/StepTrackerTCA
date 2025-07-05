//
//  WorkoutCreatorFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import WorkoutKit

@Reducer
struct WorkoutCreatorFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .workoutTitleChanged(title):
                    state.workoutTitle = title
                    return .none
                    
                case let .selectedWorkoutActivityPickerChange(item):
                    state.workoutActivityType = item
                    return .none
                    
                case let .selectedWorkoutLocationPickerChange(item):
                    state.workoutLocationType = item
                    return .none
                    
                case let .warmupGoalChanged(goal):
                    //state.warmupGoal = goal
                    return .none
                    
                case let .coolDownGoalChanged(goal):
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case .view(.cancelButtonTapped):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.workoutTitleSheetTapped):
                    state.isWorkoutTitleSheetPresented.toggle()
                    return .none
                    
                case .view(.workoutTitleSheetDismissed):
                    state.isWorkoutTitleSheetPresented = false
                    return .none
                case .view(.wodSheetTapped):
                    state.destination = .openWodCreator(WodCreatorFeature.State())
                    return .none
                case .destination:
                    return .none
                }
                
            }
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Action

/// Implementation of `WorkoutCreatorFeature` action
extension WorkoutCreatorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case selectedWorkoutActivityPickerChange(WorkoutActivityType)
        
        case selectedWorkoutLocationPickerChange(WorkoutLocationType)
        
        case workoutTitleChanged(String)
        
        case warmupGoalChanged(SimpleWorkoutGoal)
        
        case coolDownGoalChanged(SimpleWorkoutGoal)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            case cancelButtonTapped
            
            case workoutTitleSheetTapped
            
            case wodSheetTapped
            
            case workoutTitleSheetDismissed
        }
        
        case destination(PresentationAction<Destination.Action>)
    }
        
}

// MARK: - State

/// Implementation of `WorkoutCreatorFeature` state
extension WorkoutCreatorFeature {
    
    @ObservableState
    struct State {
        
        var isWorkoutTitleSheetPresented: Bool = false
        
        var workoutTitle: String = ""
        
        var workoutActivityType: WorkoutActivityType = .crossTraining
        
        var availableWorkoutTypes: [WorkoutActivityType] = [.crossTraining]
        
        var workoutLocationType: WorkoutLocationType = .indoor
        
        var warmupGoal: SimpleWorkoutGoal = .open
        
        var coolDownGoal: SimpleWorkoutGoal = .open
        
        
        @Presents var destination: Destination.State?
        
    }
    
}

/// Implementation of `WorkoutCreatorFeature` destination
extension WorkoutCreatorFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WodCreatorFeature`.
        case openWodCreator(WodCreatorFeature)
    }
    
}
   
enum SimpleWorkoutGoal: CaseIterable, Hashable {
    
    case open
    
    var title: String {
        switch self {
        case .open: return "Open"
        }
    }

}
