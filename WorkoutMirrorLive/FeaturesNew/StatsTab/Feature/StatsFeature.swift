//
//  StatsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

@Reducer
struct StatsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var authorizationManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none
                
            case let .selectedPickerChange(value):
                state.context = value
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    switch result {
                    case .success:
                        print("success")
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                    }
                }
                
            case .view(.personButtonTapped):
                state.destination = .personSettings(PersonSettingsFeature.State())
                return .none
                
                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
            case .trainingReadiness(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Scope(state: \.trainingReadiness, action: \.trainingReadiness) {
            TrainingReadinessFeature()
        }
    }
}
