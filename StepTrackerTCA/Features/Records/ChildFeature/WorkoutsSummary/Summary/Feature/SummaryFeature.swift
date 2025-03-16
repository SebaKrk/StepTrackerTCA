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
                // MARK: - Action
                
            case .getData:
                return .run { send in
                    do {
                        let data = try await services.fetchWorkoutSummary()
                        await send(.updateData(data))
                    } catch {
                        // TODO: - obsługa błędów
                        print("Error fetching workout strength data: \(error)")
                    }
                }
                
            case let .updateData(data):
                state.data = data
                state.groupedWorkouts = services.groupWorkoutsByWorkoutType(data)
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.getData)
                }
                
            case let .view(.navigationButtonTapped(workoutType)):
                if let selectedWorkout = state.groupedWorkouts?.first(where: { $0.workoutType == workoutType }) {
                    state.destination = .open(ScoresFeature.State(selectedWorkout: selectedWorkout))
                } else {
                    print("No matching wxorkout found for \(workoutType.title)")
                }
                return .none
                
                // MARK: - Destinationw

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
