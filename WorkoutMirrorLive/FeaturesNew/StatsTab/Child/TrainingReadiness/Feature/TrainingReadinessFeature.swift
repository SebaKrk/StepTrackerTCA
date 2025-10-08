//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct TrainingReadinessFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingReadinessClient) var trainingReadinessClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .internal(.changeContentState(newState)):
                state.contentState = newState
                return .none
                
            case let .internal(.readinessCalculated(result)):
                state.readinessResult = result
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.checkPremiumAccess))
                }
                
            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                return .send(.internal(.changeContentState(.error(error))))
                
            case .internal(.checkPremiumAccess):
                return .run { send in
                    let hasPremium = false
                    /// await authorizationClient.checkPremiumAccess()
                    
                    if hasPremium {
                        await send(.internal(.changeContentState(.available)))
                    } else {
                        await send(.internal(.changeContentState(.locked(.requiresPremium))))
                    }
                    
                }
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                /// sprawdź dostęp do HK , jesli jest nie przyznany to zwroć
                //await send(.internal(.changeContentState(.unauthorized)))
                /// jesli jest ok to :
                return .run { send in
                    do {
                        let result = try await trainingReadinessClient.calculate()
                        await send(.internal(.readinessCalculated(result)))
                    } catch {
                        await send(.internal(.calculationFailed(error.localizedDescription)))
                    }
                }
                
            }
        }
    }
    
}
