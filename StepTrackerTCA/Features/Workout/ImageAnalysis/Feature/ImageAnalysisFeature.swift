//
//  ImageAnalysisFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ImageAnalysisFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                    // MARK: - Destination
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ImageAnalysisFeature` action
extension ImageAnalysisFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
}

import ComposableArchitecture
import SwiftUI

/// Implementation of `ImageAnalysisFeature` state
extension ImageAnalysisFeature {
    
    @ObservableState
    struct State {

        var selectedImage: UIImage
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `ImageAnalysisFeature`.
        @Presents var destination: Destination.State?
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `ImageAnalysisFeature` destination
extension ImageAnalysisFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ImageAnalysisFeature`.
        //        case open(ScoresFeature)
    }
    
}

