//
//  WorkoutSummaryState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 13/08/2025.
//

import Foundation

/// The view state that components can take in `WorkoutSummaryState`
public enum WorkoutSummaryState {
    
    /// Indicates that the summary view is currently loading data.
    case loading
    
    /// Indicates that the summary view has successfully loaded the workout data.
    case successfullyLoaded
        
    /// Error has occurred when loading the view.
    case failed
}
