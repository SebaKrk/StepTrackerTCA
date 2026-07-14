//
//  TrainingSummaryState.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import Foundation

/// The view state that components can take in `TrainingSummaryView`
enum TrainingSummaryState {
    
    /// Indicates that the summary view is currently loading data.
    case loading
    
    /// Indicates that the summary view has successfully loaded the workout data.
    case successfullyLoaded
        
    /// Error has occurred when loading the view.
    case failed
}

