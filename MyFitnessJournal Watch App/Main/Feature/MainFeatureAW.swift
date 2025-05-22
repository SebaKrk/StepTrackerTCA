//
//  MainFeatureAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//


import ComposableArchitecture
import Foundation

@Reducer
struct MainFeatureAW {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                   
                    // MARK: - Binding Action
                case .binding(_):
                    return .none

                    // MARK: - View Action
                    
                case let .view(.selectedWorkoutOption(workout)):
                    return .send(.show(workout))
                    
                    // MARK: - Action
                    
                case .openSheet:
                    state.destination = .openSummary(SummaryFeature.State())
                    return .none
                    
                    // MARK: - Destination
                    
                case let .show(workout):
                    switch workout {
                    case .planned:
                        state.destination = .workoutSession(WorkoutSessionFeature.State())
                    case .mirroring:
                        print("mirroring")
                    case .scheduled:
                        print("scheduled")
                    case .free:
                        print("free")
                    }
                    return .none

                case .destination(.presented(.workoutSession(.controlsFeature(.view(.endButtonPressed))))):
                    print("MainFeatureAW - endButtonPressed")
                    return .send(.openSheet)
                     
                default:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}



/// Implementation of `MainFeatureAW` action
extension MainFeatureAW {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case selectedWorkoutOption(WorkoutOptionAW)
        }
        
        // MARK: - Actions
        
        ///
        case openSheet
        
        // MARK: - Destination
        
        ///
        case show(WorkoutOptionAW)
        
        ///
        case destination(PresentationAction<Destination.Action>)
    }
    
}

/// Implementation of `MainFeatureAW` state
extension MainFeatureAW {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutTypes: [WorkoutOptionAW] = [.planned, .mirroring, .scheduled, .free]
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `MainFeatureAW` destination
extension MainFeatureAW {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutSessionFeature`.
        case workoutSession(WorkoutSessionFeature)
        
        ///
        case openSummary(SummaryFeature)
    }
    
}





//case let .tabChanged(tabItem):
//    state.selectedTab = tabItem
//    return .none



// jak to ogarnać
//case .summaryFeature(.view(.doneButtonPressed)):
//  return .none

//case .summaryFeature(.binding(_)):
//   return .none
//

//                case .destination:
//                    return .none

//.ifLet(\.summaryFeature, action: \.summaryFeature) { SummaryFeature()}



///
//var summaryFeature: SummaryFeature.State?

// MARK: - Child Actions

///
//case summaryFeature(SummaryFeature.Action)
