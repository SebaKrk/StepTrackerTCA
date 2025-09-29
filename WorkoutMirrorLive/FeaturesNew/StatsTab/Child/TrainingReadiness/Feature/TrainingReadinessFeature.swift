//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrainingReadinessFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingReadinessClient) var trainingReadinessClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .internal(.readinessCalculated(result)):
                state.readinessResult = result
                return .none
                
            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                dump(error)
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
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
