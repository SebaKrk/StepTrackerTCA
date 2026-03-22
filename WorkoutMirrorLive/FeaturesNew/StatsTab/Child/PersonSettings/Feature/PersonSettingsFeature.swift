//
//  PersonSettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import Foundation
import IssueReporting
import SharedModels

@Reducer
struct PersonSettingsFeature {
    
    // MARK: - Dependency

    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.personCalculatorClient) var calculator
    @Dependency(\.apiKeyClient) var apiKeyClient
    @Dependency(\.userProfileClient) var userProfileClient
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

            case let .changeMaxHeartRate(age, sex):
                guard let age, let sex else { return .none }
                state.maxHR = calculator.calculateMaxHeartRate(age, sex)
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
                        reportIssue(error)
                    }
                }

            case .fetchUserProfile:
                return .run { send in
                    do {
                        let profile = try await userProfileClient.fetch()
                        await send(.profileLoaded(profile))
                    } catch {
                        reportIssue(error)
                    }
                }

            case let .profileLoaded(profile):
                state.userProfile = profile
                return .none

                // MARK: - View Action
            case .view(.viewDidAppear):
                return .merge(
                    .send(.fetchPersonalData),
                    .send(.fetchUserProfile)
                )

            case .view(.xMarkButtonTapped):
                return .run { _ in await self.dismiss() }

            case .view(.apiKeyTapped):
                let hasKey = apiKeyClient.load() != nil
                state.destination = .apiKey(
                    APIKeyEntryFeature.State(
                        hasExistingKey: hasKey,
                        isPresentedAsSheet: false
                    )
                )
                return .none

            case .view(.editProfileTapped):
                state.destination = .editProfile(
                    PersonProfileEditFeature.State(profile: state.userProfile)
                )
                return .none

            case .destination(.presented(.apiKey(.delegate(.keySaved)))):
                state.destination = nil
                return .none

            case .destination(.presented(.apiKey(.delegate(.keyDeleted)))):
                state.destination = nil
                return .none

            case .destination(.presented(.editProfile(.delegate(.profileSaved)))):
                state.destination = nil
                return .send(.fetchUserProfile)

            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }
    
}
