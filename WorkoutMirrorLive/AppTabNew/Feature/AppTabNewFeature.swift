//
//  AppTabNewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppTabNewFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .tabChanged(tab):
                state.selectedTab = tab
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            default:
                return .none
            }
        }
        Scope(state: \.summary, action: \.summary) {
            SummaryFeature()
        }
        Scope(state: \.workout, action: \.workout) {
            WorkoutFeature()
        }
        Scope(state: \.activities, action: \.activities) {
            ActivitiesFeature()
        }
    }
}

/// Implementation of `AppTabNewFeature` action
extension AppTabNewFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(AppScreen)
        
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
        case workout(WorkoutFeature.Action)
        
        ///
        case activities(ActivitiesFeature.Action)
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
        var workout: WorkoutFeature.State = .init()
        
        ///
        var activities: ActivitiesFeature.State = .init()
    }
    
}

