//
//  SummaryFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SummaryFeature {
    
    // MARK: - Dependencies
    
    let services: SummaryFeatureServices
    
    // MARK: - Livecycle
    
    init(service: SummaryFeatureServices) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                
            case .getData:
                return .run { send in
                    do {
                        let summary = try await services.fetchWorkoutSummary()
                        await send(.updateData(summary))
                    } catch {
                        print("Error fetching workout data: \(error)")
                    }
                }
                
            case let .updateData(summary):
                state.summary = summary
                return .run { send in
                    await send(.groupedData(summary))
                }

            case let .groupedData(summary):
                let grouped = services.groupSummaryData(summary)
                
                state.groupedMovements = services.processGroupedMovements(grouped)
                
                return .none
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.getData)
                }
                
            case let .view(.navigationButtonTapped(workoutType)):
                state.destination = .open(ScoresFeature.State(selectedWorkoutType: workoutType))
                return .none
                
                // MARK: - Destination

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
