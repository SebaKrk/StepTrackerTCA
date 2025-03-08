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
                
            case .getWorkoutStrengthData:
                return .run { send in
                    do {
                        let data = try await services.fetchWorkoutStrengthSummary()
                        await send(.updateWorkoutStrengthData(data))
                    } catch {
                        // TODO: - obsługa błędów
                        print("Error fetching workout strength data: \(error)")
                    }
                }
                
            case let .updateWorkoutStrengthData(data):
                state.data = data
                
                // TODO: - Pobierz historie Gola i wyciagnij najnowszy dla danego cwiczenia
                let goal: Double? = nil
                
                if let unwrappedData = data {
                    state.movementSummary = services.mapToMovementSummaries(goal, data: unwrappedData)
                }
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.getWorkoutStrengthData)
                }
            }
        }
    }
    
}
