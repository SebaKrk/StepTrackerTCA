//
//  LiveFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LiveFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.startWorkoutMirrorButtonTapped):
                state.destination = .workoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case .view(.deviceButtonTapped):
                state.destination = .workoutDevicePickerView(WorkoutDevicePickerFeature.State())
                return .none
                
            case .view(.navCalendarButtonTapped):
                state.destination = .calendarView(CalendarFeature.State())
                return .none
                
            case .view(.navWorkoutCreatorButtonTapped):
                state.destination = .workoutCreatorView(WorkoutCreatorFeature.State())
                return .none
                
            case .view(.viewDidAppear):
                return .none
                
            case   .destination(.presented(.calendarView(.destination(.presented(.workoutDetailsView(.destination(.presented(.workoutMirroringView(.view(.xMarkButtonTapped)))))))))):
                print("state.destination = nil, from calendarView")
                state.destination = nil
                return .none
                
            case .destination(.presented(.workoutCreatorView(.destination(.presented(.workoutMirroringView(.view(.xMarkButtonTapped))))))):
                print("state.destination = nil, from workoutCreatorView")
                state.destination = nil
                return .none
                
            case .destination(_):
                return .none
                
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `LiveFeature` action
extension LiveFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case startWorkoutMirrorButtonTapped
            
            ///
            case navCalendarButtonTapped
            
            ///
            case navWorkoutCreatorButtonTapped
            
            ///
            case deviceButtonTapped
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `LiveFeature` state
extension LiveFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from LiveFeature
        @Presents var destination: Destination.State?
    }
    
}


