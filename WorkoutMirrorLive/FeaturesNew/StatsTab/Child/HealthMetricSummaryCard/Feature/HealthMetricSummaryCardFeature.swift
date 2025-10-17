//
//  HealthMetricSummaryCardFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct HealthMetricSummaryCardFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingReadinessClient) var trainingReadinessClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Internal Action
            case let .internal(.changeContentState(newState)):
                state.contentState = newState
                return .none
                
            case let .internal(.dataLoaded(data)):
                state.components = data
                return .run {  [tier = state.subscriptionTier] send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    do {
                        let result = try await trainingReadinessClient.calculate()
                        
                        if result.healthKitAccessDenied {
                            await send(.internal(.changeContentState(.unauthorized)))
                        } else {
                            await send(.internal(.dataLoaded(result.components)))
                        }
                    } catch {
                        print("blad")
                    }
                }
                
            case let .view(.showDetailsButtonTapped(metric: metric, data: score)):
                state.destination = .details(HealthMetricSummaryDetailsCardFeature.State(metricType: metric,
                                                                                         initialData: score))
                return .none
                
                // MARK: - Destination
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

/// Implementation of `HealthMetricSummaryCardFeature` action
extension HealthMetricSummaryCardFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            ///
            case changeContentState(ContentState)
            
            ///
            case dataLoaded(TrainingReadinessComponents?)
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            //case showDetailsButtonTapped
            case showDetailsButtonTapped(metric: HealthMetricType, data: TrainingComponentScore)
        }
        
        // MARK: - Destination
        
        /// Destination case for handling navigation actions.
        /// - Parameter action: The action to be performed within the destination.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `HealthMetricSummaryCardFeature` state
extension HealthMetricSummaryCardFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic
        //@Shared var subscriptionTier: SubscriptionTier
        
        ///
        var requiredTier: SubscriptionTier = .pro
        
        ///
        var contentState: ContentState = .loading
        
        ///
        var components: TrainingReadinessComponents? = nil
        
        ///
        var hasAccess: Bool {
            guard case .ready = contentState else {
                return false
            }
            
            switch (subscriptionTier, requiredTier) {
                /// basic nie ma dostępu do pro/elite
            case (.basic, .pro), (.basic, .elite):
                return false
            case (.pro, .elite):
                /// pro nie ma dostępu do elite
                return false
            default:
                /// pozostałe przypadki = dostęp OK
                return true
            }
        }
        
        /// Represents the navigation destination state within `HealthMetricSummaryCardFeature`.
        /// This property handles transitions to different screens or modals within the feature.
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `HealthMetricSummaryCardFeature` destination
extension HealthMetricSummaryCardFeature {
    
    @Reducer
    enum Destination {
        
        ///
        case details(HealthMetricSummaryDetailsCardFeature)
    }
}

