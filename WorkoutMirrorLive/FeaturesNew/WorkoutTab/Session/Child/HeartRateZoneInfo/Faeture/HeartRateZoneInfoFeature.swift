//
//  HeartRateZoneInfoFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct HeartRateZoneInfoFeature {
    
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
                    
                case .view(.selectedZoneDescription(let zone)):
                    if state.selectedZone == zone {
                        state.selectedZone = nil
                        state.descriptionIsExpanded = false
                    } else {
                        state.selectedZone = zone
                        state.descriptionIsExpanded = zone != nil
                    }
                    return .none
                }
            }
        }
    }
    
}
