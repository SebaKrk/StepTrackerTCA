//
//  CalendarFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .workoutSelected(item):
                // tu narazie otwieram Mirroring dla testow nawigacji 
                state.destination = .workoutDetailsView(WorkoutDetailsFeature.State(workout: item!))
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `CalendarFeature` action
extension CalendarFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        case workoutSelected(String?)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `CalendarFeature` state
extension CalendarFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutCalendar: [String] = ["Trening 2314"]
        
        ///
        var selectedWorkout: String?
        
        // MARK: - Destination
        
        /// destination from CalendarFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `CalendarFeature` destination
extension CalendarFeature {
    
    @Reducer
    enum Destination {
        case workoutDetailsView(WorkoutDetailsFeature)
    }
}
