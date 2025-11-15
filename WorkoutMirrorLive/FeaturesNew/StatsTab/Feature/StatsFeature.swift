//
//  StatsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

@Reducer
struct StatsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var authorizationManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none
                
            /// Updates the user's subscription tier in persistent storage.
            case let .changeSubscriptionTier(value):
                state.$subscriptionTier.withLock { $0 = value }
                return .none
                
            /// Initializes the TrainingReadinessFeature state.
            case .initializeTrainingReadiness:
                state.trainingReadiness = .init()
                return .none
                
            /// Initializes the HealthMetricSummaryCardFeature state.
            case .initializeSummaryCard:
                state.summaryCard = .init()
                return .none
                
            /// Initializes the RingActivitiesSummaryFeature state.
            case .initializeRingActivitiesSummary:
                state.ringActivitiesSummary = .init()
                return .none
                
            /// Initializes all child feature states after successful authorization.
            case .initializeChildren:
                return .merge(
                    .send(.initializeTrainingReadiness),
                    .send(.initializeSummaryCard),
                    .send(.initializeRingActivitiesSummary)
                )
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                guard state.trainingReadiness == nil else {
                    return .none
                }
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    
                    switch result {
                    case .success:
                        await send(.initializeChildren)
                        await send(.changeViewState(.success))
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                        await send(.changeViewState(.failed))
                    }
                }
                
            /// Checks whether the DataAnalyzer API is available on the current device (iOS 26+).
            case .view(.checkDataAnalyzerAvailability):
                if #available(iOS 26, *) {
                    let isAvailable = DataAnalyzer.shared.available
                    state.isDataAnalyzerAvailable = isAvailable
                }
                return .none
                
            case .view(.pullToRefresh):
                return .merge(
                    .send(.trainingReadiness(.view(.refresh))),
                    .send(.summaryCard(.view(.refresh))),
                    .send(.ringActivitiesSummary(.view(.refresh))),
                    .send(.changeViewState(.success))
                )
                
            /// Triggered when the user taps the person/profile button in the navigation bar.
            /// Typically opens the user settings screen.
            case .view(.personButtonTapped):
                state.destination = .personSettings(PersonSettingsFeature.State())
                return .none
                
            /// Triggered when the user selects a subscription tier option.
            /// Sends the chosen tier as an associated value.
            case let .view(.subscriptionTierButtonTapped(value)):
                return .send(.changeSubscriptionTier(value))
                
                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
                
            case .trainingReadiness(_):
                return .none
                
            case .summaryCard(_):
                return .none
                
            case .ringActivitiesSummary(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.trainingReadiness, action: \.trainingReadiness) {
            TrainingReadinessFeature()
        }
        .ifLet(\.summaryCard, action: \.summaryCard) {
            HealthMetricSummaryCardFeature()
        }
        .ifLet(\.ringActivitiesSummary, action: \.ringActivitiesSummary) {
            RingActivitiesSummaryFeature()
        }
    }
    
}
