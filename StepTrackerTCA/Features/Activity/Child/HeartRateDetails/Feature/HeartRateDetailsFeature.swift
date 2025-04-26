//
//  HeartRateDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

@Reducer
struct HeartRateDetailsFeature {
    
    // MARK: - Properties
    
    var service: HeartRateDetailsService
    
    // MARK: - Lifecycle
    
    init(service: HeartRateDetailsService = DefaultHeartRateDetailsService()) {
        self.service = service
    }
    
    // MARK: - State
    @ObservableState
    struct State {
        
        var workout: HKWorkout
        
        var sample: [HKQuantitySample] = []
    }
    
    // MARK: - Action
    @CasePathable
    enum Action: ViewAction {
        
        case fetch
        
        case updateData(Result<[HKQuantitySample], Error>)
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .fetch:
                return .run { [workout = state.workout] send in
                    await send(.updateData(Result {
                        try await service.fetchHeartRateSamples(for: workout)
                    }))
                }
                
            case let .updateData(.success(data)):
                state.sample = data
                dump(data)
                return .none
                
            case let .updateData(.failure(error)):
                print("❌ Failed to sample data: \(error.localizedDescription)")
                return .none
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.fetch)
                }
            }
            
        }
    }
    
}
