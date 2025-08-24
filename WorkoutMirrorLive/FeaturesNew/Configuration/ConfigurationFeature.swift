//
//  ConfigurationFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct ConfigurationFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Core Action
            case let .core(.changeViewState(viewState)):
                state.viewState = viewState
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
            case .device(.select):
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.core(.changeViewState(.activity)), animation: .bouncy)
                }
                
            case .device(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        Scope(state: \.device, action: \.device) {
            DeviceFeature()
        }
    }
}

extension ConfigurationFeature {
    
    enum CancelID: Hashable, Sendable {
        
        case advance
    }
}

/// Implementation of `ConfigurationFeature` action
extension ConfigurationFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Core Actions
        
        case core(Internal)
        
        enum Internal {
            
            ///
            case changeViewState(SetupPhase)
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case closeButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        ///
        case device(DeviceFeature.Action)
    }
}

/// Implementation of `ConfigurationFeature` state
extension ConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: SetupPhase = .device
        
        
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        ///
        var device: DeviceFeature.State = .init()
    }
    
}

/// Implementation of `ConfigurationFeature` destination
extension ConfigurationFeature {
    
    @Reducer
    enum Destination {
        
    }
}


