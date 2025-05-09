//
//  WeightGoalTest+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalTest` state
extension WeightGoalTest {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        var addDataDate: Date = .now
        
        var value: String = ""
        
        var weightGoal: Double? = nil 
    }
    
}
