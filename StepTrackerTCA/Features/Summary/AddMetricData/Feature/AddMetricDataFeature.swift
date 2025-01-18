//
//  AddMetricDataFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddMetricDataFeature {
    
    // MARK: - Properties
    // MARK: - TODO czy na pewno chce tu to inicializować ?
    var addMetricDataService = DefaultAddMetricService()
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce {
                state,
                action in
                switch action {
                    
                    // MARK: - Actions
                    
                    // MARK: - View Actions
                    
                case .view(.addDataButtonPressed):
                    
                    guard !state.valueToAdd.isEmpty else {
                        let alertMessage = "Podaj wartość"
                        state.alertMessage = alertMessage
                        return .run { send in
                            await send(.presentAlert)
                        }
                    }
                
                    return .run { [metric = state.healthMetric, date = state.addDataDate, value = state.valueToAdd] send in
                        switch metric {
                        case .steps:
                            try await addMetricDataService.addHealthData(
                                for: date,
                                value: Double(value) ?? 0,
                                type: .stepCount,
                                unit: .count()
                            )
                        case .weight:
                            try await addMetricDataService.addHealthData(
                                for: date,
                                value: Double(value) ?? 0,
                                type: .bodyMass,
                                unit: .gramUnit(with: .kilo)
                            )
                        default:
                            print("Unsupported metric type")
                        }
                        // TODO: -
                        await send(.view(.dismissButtonPressed))
                    }
                    
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                    // MARK: - Alert actions
                    
                case .presentAlert:
                    guard let alertMessage = state.alertMessage else { return .none }
                    state.alert = .infoAlert(with: alertMessage)
                    state.alertMessage = nil
                    return .none
                    
                case .alert(.dismiss):
                    state.alert = nil
                    return .none
                    
                default: return .none
                }
            }
        }
    }
    
}
