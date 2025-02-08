//
//  WeightLiftingGoalsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// A protocol defining the service responsible for managing WeightLifting goals.
protocol WeightLiftingGoalsServices {
    
}

import Factory
import Foundation

final class  DefaultWeightLiftingGoalsServices: WeightLiftingGoalsServices {
    
}

import ComposableArchitecture
import Foundation

@Reducer
struct WeightLiftingGoalsFeature {
    
    // MARK: - Dependencies
    
    let weightLiftingGoalsServices: WeightLiftingGoalsServices

    // MARK: - Livecycle
    
    init(service: WeightLiftingGoalsServices) {
        self.weightLiftingGoalsServices = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
                
            case .show:
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` action
extension WeightLiftingGoalsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
        
        // MARK: - Destination
        
        /// Triggered to display a destination or handle navigation actions.
        case show
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` state
extension WeightLiftingGoalsFeature {
    @ObservableState
    struct State {
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from `WeightLiftingGoalsFeature`
        @Presents var destination: Destination.State?
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` destination
extension WeightLiftingGoalsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `Tu dać feature`.
        case open(SetWeightGoalFeature)
    }
    
}

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightLiftingGoalsFeature.self)
struct WeightLiftingGoalsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightLiftingGoalsFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            Text("WeightLiftingGoalsFeature")
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    // do zmiany
                    SetWeightGoalView(store: store)
                }
    }
    
}

#Preview {
    WeightLiftingGoalsView(store: Store(initialState: WeightLiftingGoalsFeature.State(), reducer: {
        WeightLiftingGoalsFeature(service: DefaultWeightLiftingGoalsServices())
    }))
}
