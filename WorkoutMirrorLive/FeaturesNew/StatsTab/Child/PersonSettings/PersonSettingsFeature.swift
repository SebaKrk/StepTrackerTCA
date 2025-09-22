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
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeAge(age):
                state.age = age
                return .none
                
            case let .changeSex(sex):
                state.sex = sex
                return .none
                
            case let .changeHeight(height):
                state.height = height
                return .none
                
            case let .changeWeight(weight):
                state.weight = weight
                return .none
                
            case let .changeRestingHeartRate(restingHeartRate):
                state.restingHeartRate = restingHeartRate
                return .none
            
            case .fetchPersonalData:
                return .run { send in
                    do {
                        let age = try await personalDataClient.getAge()
                        let sex = try await personalDataClient.getBiologicalSex()
                        let height = try await personalDataClient.getHeight()
                        let weight = try await personalDataClient.getWeight(1)
                        let restingHR = try await personalDataClient.getRestingHeartRate(7)
                        
                        await send(.changeAge(age?.description ?? "-"))
                        await send(.changeSex(sex ?? "-"))
                        await send(.changeHeight(height != nil ? "\(Int(height!.value)) cm" : "-"))
                        await send(.changeWeight(weight != nil ? "\(Int(weight!.value)) kg" : "-"))
                        await send(.changeRestingHeartRate(restingHR != nil ? "\(Int(restingHR!.value)) bpm" : "-"))
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
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `PersonSettingsFeature` action
extension PersonSettingsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        case changeAge(String)
        
        case changeSex(String)
        
        case changeHeight(String)
        
        case changeWeight(String)
        
        case changeRestingHeartRate(String)
        
        case fetchPersonalData
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case xMarkButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `PersonSettingsFeature` state
extension PersonSettingsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var age: String = "-"
        
        var sex: String = "-"
        
        var height: String = "-"
        
        var weight: String = "-"
        
        var restingHeartRate: String = "-"
        
        // MARK: - Destination
        
        /// destination from PersonSettingsFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `PersonSettingsFeature` destination
extension PersonSettingsFeature {
    
    @Reducer
    enum Destination {

    }
}


