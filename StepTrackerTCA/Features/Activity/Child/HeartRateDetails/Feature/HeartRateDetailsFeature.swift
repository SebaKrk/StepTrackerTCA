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
        
        ///
        var workout: HKWorkout
        
        ///
        var sample: [HKQuantitySample] = []
        
        ///
        var hrData: [HeartRateMetricsMinute] = []
        
        ///
        var workoutType: String { workout.workoutActivityType.name }
        
        ///
        var startWorkout: Date { workout.startDate }
        
        ///
        var endWorkout: Date { workout.endDate }
        
        ///
        var isExpandDetails: Bool = false
        
    }
    
    // MARK: - Action
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        ///
        case fetch
        
        ///
        case updateData(Result<[HKQuantitySample], Error>)
        
        ///
        case calculateMinuteHRStats
        
        ///
        case updateHRMetric([HeartRateMetricsMinute])
        //([HKQuantitySample])
        
        
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
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                case .fetch:
                    return .run { [workout = state.workout] send in
                        await send(.updateData(Result {
                            try await service.fetchHeartRateSamples(for: workout)
                        }))
                    }
                    
                case let .updateData(.success(data)):
                    state.sample = data
                    return .run { send in
                        await send(.calculateMinuteHRStats)
                    }
                    
                case let .updateData(.failure(error)):
                    print("❌ Failed to sample data: \(error.localizedDescription)")
                    return .none
                    
                case .calculateMinuteHRStats:
                    return .run { [sample = state.sample] send in
                        let hrData = service.calculateMinuteHRStats(from: sample)
                        await send(.updateHRMetric(hrData))
                    }
                    
                case let .updateHRMetric(data):
                    state.hrData = data
                    return .none
                    
                    // MARK: - ViewActions
                case .view(.viewDidAppear):
                    return .run { send in
                        await send(.fetch)
                    }
                }
            }
        }
    }
    
}
