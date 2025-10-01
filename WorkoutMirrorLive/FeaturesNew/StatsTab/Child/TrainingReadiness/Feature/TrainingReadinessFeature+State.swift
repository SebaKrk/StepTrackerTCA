//
//  TrainingReadinessFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `TrainingReadinessFeature` state
extension TrainingReadinessFeature {
    
    @ObservableState
    struct State {
        
        var contentState: ContentState = .loading
        
        /// Training readiness calculation result
        var readinessResult: TrainingReadinessResult?
        
        /// Error message if calculation fails
        var errorMessage: String?
        
        /// Computed readiness value (0-100)
        var readinessValue: Int {
            readinessResult?.overallScore ?? 0
        }
        
        /// Computed readiness level
        var readinessLevel: ReadinessLevel {
            readinessResult?.readinessLevel ?? .veryPoor
        }
        
        /// Computed readiness label
        var readinessLabel: String {
            readinessLevel.rawValue
        }
        
        /// Whether result is reliable (enough data available)
        var isReliable: Bool {
            readinessResult?.isReliable ?? false
        }
    }
}
