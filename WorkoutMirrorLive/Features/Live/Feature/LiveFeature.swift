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
                state.destination = .openWorkoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case .view(.navCalendarButtonTapped):
                state.destination = .openCalendarView(CalendarFeature.State())
                return .none
                
            case .view(.viewDidAppear):
                return .none
                
            case   .destination(.presented(.openCalendarView(.destination(.presented(.openWorkoutDetailsView(.destination(.presented(.openWorkoutMirroringView(.view(.xMarkButtonTapped)))))))))):
                print("state.destination = nil")
                state.destination = nil
                return .none
            case .destination(_):
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

/// Implementation of `LiveFeature` destination
extension LiveFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutMirroringFeature`.
        case openWorkoutMirroringView(WorkoutMirroringFeature)
        
        /// Represents the destination for displaying in `CalendarFeature`.
        case openCalendarView(CalendarFeature)
    }
}

