//
//  StatsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import OSLog
import SharedModels

@Reducer
struct StatsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var authorizationManager
    @Dependency(\.dataAnalyzerClient) var dataAnalyzerClient 
    @Dependency(\.trainingReadinessBackgroundManager) var trainingReadinessBackgroundManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none
                
            case let .selectedPickerChange(value):
                state.context = value
                if value == .analytics, state.analytics == nil {
                    return .send(.initializeAnalytics)
                }
                if value == .exercises, state.exerciseAnalytics == nil {
                    return .send(.initializeExerciseAnalytics)
                }
                return .none
                
            case let .changeSubscriptionTier(value):
                state.$subscriptionTier.withLock { $0 = value }
                return .none
                
            case let .updateDataAnalyzer(isAvailable):
                state.isDataAnalyzerAvailable = isAvailable
                return .none
                
            case .initializeTrainingReadiness:
                state.trainingReadiness = .init()
                return .none
                
            case .initializeSummaryCard:
                state.summaryCard = .init()
                return .none
                
            case .initializeRingActivitiesSummary:
                state.ringActivitiesSummary = .init()
                return .none

            case .initializeAnalytics:
                state.analytics = AnalyticsFeature.State()
                return .none

            case .initializeExerciseAnalytics:
                state.exerciseAnalytics = ExerciseAnalyticsFeature.State()
                return .none
                
            case .initializeChildren:
                return .merge(
                    .send(.initializeTrainingReadiness),
                    .send(.initializeSummaryCard),
                    .send(.initializeRingActivitiesSummary)
                )
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                // Already initialized - observation is running, nothing to do
                guard state.trainingReadiness == nil else {
                    return .none
                }
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    
                    switch result {
                    case .success:
                        await send(.initializeChildren)
                        await send(.changeViewState(.success))
                        await send(.startObserving)
                        
                    case .failure(let error):
                        Logger.stats.error("Authorization failed: \(error.localizedDescription, privacy: .public)")
                        await send(.changeViewState(.failed))
                    }
                }

            case .view(.viewDidDisappear):
                // Observation intentionally kept alive — background updates need to flow
                // even when the Stats tab is not on screen.
                return .none

            case .startObserving:
                return .run { send in
                    for await update in await trainingReadinessBackgroundManager.healthDataUpdates() {
                        await send(.healthDataUpdated(update))
                    }
                }
                .cancellable(id: StatsFeatureCancelID.observation)
                
            case let .healthDataUpdated(update):
                // Trigger refresh for all sensitive components
                return .send(.view(.pullToRefresh))
                
            case .view(.checkDataAnalyzerAvailability):
                return .run { send in
                    let isAvailable = try await dataAnalyzerClient.isAvailable()
                    await send((.updateDataAnalyzer(isAvailable)))
                }
                
            case .view(.dataAnalyzerButtonTapped):
                state.destination = .readinessAnalysis(ReadinessAnalysisFeature.State())
                return .none
                
            case .view(.pullToRefresh):
                var effects: [Effect<Action>] = [
                    .send(.trainingReadiness(.view(.refresh))),
                    .send(.summaryCard(.view(.refresh))),
                    .send(.ringActivitiesSummary(.view(.refresh))),
                    .send(.changeViewState(.success))
                ]
                if state.analytics != nil {
                    effects.append(.send(.analytics(.view(.refresh))))
                }
                return .merge(effects)
                
            case .view(.personButtonTapped):
                state.destination = .personSettings(PersonSettingsFeature.State())
                return .none
                
            case let .view(.subscriptionTierButtonTapped(value)):
                return .send(.changeSubscriptionTier(value))
                
                // MARK: - Destination
                
            case .destination(_):
                return .none
                
                // MARK: - Child
                
            case .trainingReadiness(.delegate(.refreshRequested)):
                return .send(.view(.pullToRefresh))
                
            case .trainingReadiness(_):
                return .none
                
            case .summaryCard(_):
                return .none
                
            case .ringActivitiesSummary(_):
                return .none

            case .analytics(_):
                return .none

            case .exerciseAnalytics(_):
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
        .ifLet(\.analytics, action: \.analytics) {
            AnalyticsFeature()
        }
        .ifLet(\.exerciseAnalytics, action: \.exerciseAnalytics) {
            ExerciseAnalyticsFeature()
        }
    }
      
}
