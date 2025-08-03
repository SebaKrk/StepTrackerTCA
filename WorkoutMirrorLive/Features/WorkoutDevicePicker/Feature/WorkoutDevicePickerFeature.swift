//
//  WorkoutDevicePickerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 03/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutDevicePickerFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .selectedWorkout(workout):
                state.selectedWorkout = workout
                return .none
                
                // MARK: - View Action
            case .view(.watchButtonTapped):
                state.destination = .workoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case .view(.iPhoneButtonTapped):
                state.destination = .workoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case let .view(.selectedWorkoutButtonTapped(workout)):
                return .send(.selectedWorkout(workout))
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `WorkoutDevicePickerFeature` action
extension WorkoutDevicePickerFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        case selectedWorkout(String)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case watchButtonTapped
            
            ///
            case iPhoneButtonTapped
            
            case selectedWorkoutButtonTapped(String)
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutDetailsFeature` state
extension WorkoutDevicePickerFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var selectedWorkout: String?
        
        // MARK: - Destination
        
        /// destination from WorkoutDevicePickerFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `WorkoutDevicePickerFeature` destination
extension WorkoutDevicePickerFeature {
    
    @Reducer
    enum Destination {
        case workoutMirroringView(WorkoutMirroringFeature)
    }
    
}

