//
//  ActivitiesFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ActivitiesFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Action
                
            case let .selectedPickerChange(value):
                state.context = value
                return .none
                
                // MARK: - Child Features
                
            case .personalActivity:
                return .none
                
            case .plans:
                return .none
            }
        }
        Scope(state: \.personalActivity, action: \.personalActivity) {
            PersonalActivityFeature()
        }
        Scope(state: \.plans, action: \.plans) {
            PlansFeature()
        }
    }
    
}
