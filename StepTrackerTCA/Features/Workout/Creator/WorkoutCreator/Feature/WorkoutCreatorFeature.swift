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
                
//            case let .warmupGoalChanged(goal):
//                state.warmupGoal = goal
//                return .none
                
            case let .warmupTimeChange(time):
                state.warmUpGoalTime = time
                return .none
                
            case let .coolDownGoalChanged(goal):
                state.coolDownGoal = goal
                return .none
                
            case let .coolDownTimeChange(time):
                state.coolDownTime = time
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
                
            case .view(.openWarmUpSheetPresented):
                state.isWarmUpSheetPresented.toggle()
                return .none
                
            case let .view(.warmupGoalButtonTapped(goal)):
                state.warmupGoal = goal
                return .none
                
                // MARK: - Destination
  
                
                // MARK: - Child
            case let .destination(.presented(.openWodCreator(.delegate(.wodCreated(workout))))):
                print("Otrzymano workout:")
                dump(workout)
                return .none
                
            case .destination:
                return .none
            }
            
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
