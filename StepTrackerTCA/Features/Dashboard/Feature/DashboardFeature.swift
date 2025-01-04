//
//  DashboardFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Factory
import Foundation

@Reducer
struct DashboardFeature {
    
    // MARK: - Properties
    
    var dashboardFeatureService: DashboardFeatureService
    
    // MARK: - Lifecycle
    
    init(service: DashboardFeatureService) {
        self.dashboardFeatureService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Actions
                    
                case let .selectedPickerChange(item):
                    state.healthMetric = item
                    return .none
                    
                case .changeIsFirstAppearance:
                    state.hasSeenPermissionPriming = dashboardFeatureService.hasSeenPermissionPriming
                    return .none
                
                case .fetchHealthData:
                    return .run { send in
                        await send(.updateStepChartData(
                            Result {
                                try await dashboardFeatureService.getStepsData()
                            }
                        ))
                    }
                    
                case let .updateStepChartData(.success(data)):
                    state.stepData = data
                    return .none
                    
                    // TODO: Error handling
                    /// Add failure handling to the fetchHealthData
                case let .updateStepChartData(.failure(error)):
                    print(error.localizedDescription)
                    return .none
                    
                    // MARK: - View actions
                    
                case .view(.viewDidAppear):
                    if !dashboardFeatureService.hasSeenPermissionPriming {
                        return .run { send in
                            await send(.openPermissionScreen)
                        }
                    } else {
                        return .run { send in
                            try await dashboardFeatureService.getDummyData()
                            await send(.fetchHealthData)
                        }
                    }
                    
                case .openPermissionScreen:
                    dashboardFeatureService.markPermissionPrimingAsSeen()
                    state.destination = .openHealthKitPermissionScreen(HealthKitPermissionFeature.State())
                    return .none
                    
                    // MARK: - Path
                    
                case let .path(action):
                    switch action {
                    case .element(id: _, action: .healthDataListFeature(.navigateToHealthDataList)):
                        state.path.append(.healthDataListFeature(HealthDataListFeature.State(healthMetric: state.healthMetric)))
                        return .none
                        
                    default: return .none
                    }
                    
                default: return .none
                }
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
    
}
