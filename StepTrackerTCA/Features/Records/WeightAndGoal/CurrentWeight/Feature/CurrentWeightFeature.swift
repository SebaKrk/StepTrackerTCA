//
//  CurrentWeightFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CurrentWeightFeature {
    
    // MARK: - Properties
    
    var currentWeightService: CurrentWeightService
    
    // MARK: - Lifecycle
    
    init(service: CurrentWeightService) {
        self.currentWeightService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
            case let .updateWeightData(data):
                state.latestWeight = currentWeightService.getLatestWeightData(from: data)
                return .none
                
                // MARK: - View Actions
            case .view(.viewDidAppear):
                print("CurrentWeightFeature")
                return .none
      
            }
        }
    }
    
}
