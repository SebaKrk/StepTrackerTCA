//
//  PersonSettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct PersonSettingsFeature {
    
    // MARK: - Dependency

    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.personCalculatorClient) var calculator
    @Dependency(\.apiKeyClient) var apiKeyClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeAge(age):
                if let age = age {
                    state.age = "\(age)"
                }
                return .none
                
            case let .changeSex(sex):
                if let sex = sex {
                    state.sex = sex.displayName
                }
                return .none
                
            case let .changeHeight(height):
                if let height = height?.value {
                    state.height = "\(height)"
                }
                return .none
                
            case let .changeWeight(weight):
                if let weight = weight?.value {
                    state.weight = String(format: "%.1f", weight)
                }
                return .none
                
            case let .changeRestingHeartRate(restingHeartRate):
                if let restingHeartRate = restingHeartRate?.value {
                    state.restingHeartRate = "\(Int(restingHeartRate))"
                }
                return .none
                
            case let .changeMaxHeartRate(age, sex):
                guard let age = age, let sex = sex else {
                    return .none
                }
                
                let maxHR = calculator.calculateMaxHeartRate(age, sex)
                state.maxHR = "\(maxHR)"
                
                return .none
                
            case .fetchPersonalData:
                return .run { send in
                    do {
                        let age = try await personalDataClient.getAge()
                        let sex = try await personalDataClient.getBiologicalSex()
                        let height = try await personalDataClient.getHeight()
                        let weight = try await personalDataClient.getWeight(30)
                        let restingHR = try await personalDataClient.getRestingHeartRate(7)
                        
                        await send(.changeAge(age))
                        await send(.changeSex(sex))
                        await send(.changeHeight(height))
                        await send(.changeWeight(weight))
                        await send(.changeRestingHeartRate(restingHR))
                        await send(.changeMaxHeartRate(age, sex))
                        
                    } catch {
                        print("Failed to fetch personal data: \(error)")
                    }
                }
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .send(.fetchPersonalData)
                
            case .view(.xMarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }

            case .view(.apiKeyTapped):
                let hasKey = apiKeyClient.load() != nil
                state.destination = .apiKey(
                    APIKeyEntryFeature.State(
                        hasExistingKey: hasKey,
                        isPresentedAsSheet: false
                    )
                )
                return .none

            case .destination(.presented(.apiKey(.delegate(.keySaved)))):
                state.destination = nil
                return .none

            case .destination(.presented(.apiKey(.delegate(.keyDeleted)))):
                state.destination = nil
                return .none

            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }
    
}
