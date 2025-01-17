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
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                case .changeIsFirstAppearance:
                    state.isFirstAppearance = false
                    state.hasSeenPermissionPriming = dashboardFeatureService.hasSeenPermissionPriming
                    return .none
                    
                case let .selectedPickerChange(item):
                    state.healthMetric = item
                    return .none
                    
                case .fetchHealthData:
                    return .run { send in
                        await send(.updateStepChartData(
                            Result {
                                try await dashboardFeatureService.getStepsData()
                            }
                        ))
                        
                        await send(.updateWeightChartData(
                            Result {
                                try await dashboardFeatureService.getWeightData()
                            }
                        ))
                        
                    }
                    
                    // StepData
                case let .updateStepChartData(.success(data)):
                    state.stepData = data
                    return .none
                    
                case let .updateStepChartData(.failure(error)):
                    print(error.localizedDescription)
                    return .none
                    
                    // WeightData
                case let .updateWeightChartData(.success(data)):
                    state.weightData = data
                    return .none
                    
                case let .updateWeightChartData(.failure(error)):
                    print(error.localizedDescription)
                    return .none
                    
                    // MARK: - View actions
                case .view(.viewDidAppear):
                    if !dashboardFeatureService.hasSeenPermissionPriming {
                        return .run { send in
                            await send(.openPermissionScreen)
                        }
                    } else {
                        return .run { [state] send in
                            if state.isFirstAppearance {
                                /// use only first time
                                //try await dashboardFeatureService.getDummyData()
                                await send(.fetchHealthData)
                                await send(.changeIsFirstAppearance)
                            }
                        }
                    }
                    
                    // MARK: - Destination
                case .openPermissionScreen:
                    dashboardFeatureService.markPermissionPrimingAsSeen()
                    state.destination = .openHealthKitPermissionScreen(HealthKitPermissionFeature.State())
                    return .none
                    
                default: return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
