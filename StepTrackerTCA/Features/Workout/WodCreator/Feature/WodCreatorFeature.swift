//
//  WodCreatorFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WodCreatorFeature {
    
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

            case let .wodTitleChanged(title):
                state.wodTitle = title
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
            case .view(.wodTitleSheetTapped):
                state.isWodTitleSheetPresented.toggle()
                return .none
                
            case .view(.wodTitleSheetDismissed):
                state.isWodTitleSheetPresented = false
                return .none
            }
        }
    }
    
}
// MARK: - Action

/// Implementation of `WodCreatorFeature` action
extension WodCreatorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case wodTitleChanged(String)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            case wodTitleSheetTapped
            
            case wodTitleSheetDismissed
        }
    }
}

// MARK: - State

/// Implementation of `WodCreatorFeature` state
extension WodCreatorFeature {
    
    @ObservableState
    struct State {
        
        var isWodTitleSheetPresented: Bool = false
        
        var wodTitle: String = ""
    }
}

