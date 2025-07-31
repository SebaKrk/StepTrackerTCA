//
//  AppTabFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 30/07/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppTabFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .tabChanged(tab):
                state.selectedTab = tab
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            }
        }
    }
}

/// Implementation of `AppTabFeature` action
extension AppTabFeature {
    
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
    }
}

/// Implementation of `AppTabFeature` state
extension AppTabFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// List of available tabs in the application.
        ///
        /// The order of tabs determines their placement in the UI.
        var tabs: [AppScreen] = [.workout, .live, .person]
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.summary`.
        var selectedTab: AppScreen = .live
    }
    
}
