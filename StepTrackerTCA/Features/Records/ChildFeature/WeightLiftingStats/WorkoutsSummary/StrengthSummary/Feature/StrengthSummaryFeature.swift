//
//  StrengthSummaryFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StrengthSummaryFeature {
    
    // MARK: - Dependencies
    
    let services: StrengthSummaryServices
    
    // MARK: - Livecycle
    
    init(service: StrengthSummaryServices) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthSummaryFeature` action
extension StrengthSummaryFeature {
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            case viewDidAppear
        }
        
        // MARK: - Destination
        
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthSummaryFeature` destination
extension StrengthSummaryFeature {
    
    @Reducer
    enum Destination {
        
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthSummaryFeature` state
extension StrengthSummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
    }
    
}

protocol StrengthSummaryServices {
    
}

final class DefaultStrengthSummaryServices: StrengthSummaryServices {
    
}




import ComposableArchitecture
import SwiftUI

@ViewAction(for: StrengthSummaryFeature.self)
struct StrengthSummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StrengthSummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("StrengthSummaryFeature")
    }
    
}
