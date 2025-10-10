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
                
            case let .changeSubscriptionTier(value):
                state.$subscriptionTier.withLock { $0 = value }
                return .none
                
            case .initializeTrainingReadiness:
                state.trainingReadiness = .init(subscriptionTier: state.$subscriptionTier)
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    switch result {
                    case .success:
                        await send(.changeViewState(.success))
                        await send(.initializeTrainingReadiness)
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                        await send(.changeViewState(.failed))
                    }
                }
                
            case .view(.personButtonTapped):
                state.destination = .personSettings(PersonSettingsFeature.State())
                return .none
                
            case let  .view(.subscriptionTierButtonTapped(value)):
                return .send(.changeSubscriptionTier(value))
                
                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
            case .trainingReadiness(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.trainingReadiness, action: \.trainingReadiness) {
               TrainingReadinessFeature()
           }
    }
}
