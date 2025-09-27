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
        
        var readinessValue: Int = 74
        
        var readinessLevel: ReadinessLevel {
            ReadinessLevel(from: readinessValue)
        }
        
        var readinessLabel: String {
            readinessLevel.rawValue
        }
    }
}
