//
//  TrainingReadinessFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/09/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Implementation of `TrainingReadinessFeature` state
extension TrainingReadinessFeature {
    
    @ObservableState
    struct State {
        
        ///
        //@Shared var subscriptionTier: SubscriptionTier
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic
        
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        ///
        var requiredTier: SubscriptionTier = .pro
        
        ////
        var contentState: ContentState = .noData
        
        /// Training readiness calculation result
        var readinessResult: TrainingReadinessResult?

        /// Whether a score can exist yet today
        var availability: ReadinessAvailability = .available

        /// Whether the card should explain that the night is not over yet
        var isAwaitingSleepData: Bool {
            if case .awaitingSleepData = availability { return true }
            return false
        }

        /// When a result is expected, for the waiting copy
        var sleepDataExpectedBy: Date? {
            guard case let .awaitingSleepData(expectedBy) = availability else { return nil }
            return expectedBy
        }

        /// Whether the readiness level belongs on screen
        ///
        /// Without a score there is no level — `readinessLevel` would fall back
        /// to `.fair` and state something the data does not support.
        var isReadinessLevelVisible: Bool {
            contentState.isReady && !isAwaitingSleepData
        }
        
        /// Error message if calculation fails
        var errorMessage: String?
        
        /// Computed readiness value (0-100)
        var readinessValue: Int {
            readinessResult?.overallScore ?? 0
        }
        
        /// Computed readiness level
        var readinessLevel: ReadinessLevel {
            readinessResult?.readinessLevel ?? .fair
        }
        
        /// Computed readiness label
        var readinessLabel: String {
            readinessLevel.title
        }
        
        /// Whether result is reliable (enough data available)
        var isReliable: Bool {
            readinessResult?.isReliable ?? false
        }
    }
    
}
