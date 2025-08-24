//
//  AppTabNewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct AppTabNewFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .tabChanged(tab):
                if tab == .workout {
                    return .send(.activateWorkoutView)
                } else {
                    state.selectedTab = tab
                    return .none
                }
                
            case .activateWorkoutView:
                //state.destination = .workout(WorkoutFeature.State())
                state.destination = .workoutConfiguration(ConfigurationFeature.State())
                return .none
                
            case let .activateWorkoutSessionView(workout):
                state.destination = .session(WorkoutSessionFeature.State(selectedWorkout: workout))
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
            case let .destination(.presented(.workoutConfiguration(.delegate(.start(workout))))):
                return .run { send in
                    await send(.activateWorkoutSessionView(workout))
                }
                
            case .destination:
                return .none
                
            default:
                return .none
            }
        }
        
        Scope(state: \.summary, action: \.summary) {
            SummaryFeature()
        }
        Scope(state: \.activities, action: \.activities) {
            ActivitiesFeature()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `AppTabNewFeature` action
extension AppTabNewFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(AppScreen)
        
        ///
        case activateWorkoutView
        
        ///
        case activateWorkoutSessionView(WorkoutType)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Child
        
        ///
        case summary(SummaryFeature.Action)

        ///
        case activities(ActivitiesFeature.Action)
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `AppTabNewFeature` state
extension AppTabNewFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// List of available tabs in the application.
        ///
        /// The order of tabs determines their placement in the UI.
        var tabs: [AppScreen] = [.summary, .activities, .workout]
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.summary`.
        var selectedTab: AppScreen = .live
        
        // MARK: - Child
        
        ///
        var summary: SummaryFeature.State = .init()
        
        ///
        var activities: ActivitiesFeature.State = .init()
        
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `AppTabNewFeature` destination
extension AppTabNewFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutFeature`.
        case workout(WorkoutFeature)
        
        /// Represents the destination for displaying in `ConfigurationFeature`.
        case workoutConfiguration(ConfigurationFeature)
        
        /// Represents the destination for displaying in `WorkoutSessionFeature`.
        case session(WorkoutSessionFeature)

    }
}

