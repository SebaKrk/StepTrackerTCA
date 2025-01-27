//
//  PersonDataFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PersonDataFeature {
    
    // MARK: - Properties
    
    var personDataFeatureService: PersonDataFeatureService
    
    // MARK: - Lifecycle
    
    init(service: PersonDataFeatureService) {
        self.personDataFeatureService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
            case .fetchHealthData:
                return .run { send in
                    await send(.updateWeightData(
                        Result {
                            try await personDataFeatureService.getWeightData()
                        }
                    ))
                }
                
            case let .updateWeightData(.success(data)):
                state.weightData = data
                return .run { send in
                    await send(.currentWeight(.updateWeightData(data)))
                }
                
            case let .updateWeightData(.failure(error)):
                print(error.localizedDescription)
                return .none
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.fetchHealthData)
                }
                
                // MARK: - Destination
            case .destination:
                return .none
             
                // MARK: - Child actions
            case .currentWeight:
                return .none
                
            case .weightGoal:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Scope(state: \.currentWeight, action: \.currentWeight) {
            CurrentWeightFeature(service: DefaultCurrentWeightService())
        }
        Scope(state: \.weightGoal, action: \.weightGoal) {
            WeightGoalFeature(service: DefaultWeightGoalServices())
        }
    }
    
}
