//
//  SummaryState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import Foundation

enum SummaryState {
    
    /// Indicates that the summary view is currently loading data.
    case loading
    
    /// Indicates that the summary view has successfully loaded the workout data.
    case successfullyLoaded
        
    /// Error has occurred when loading the view.
    case failed
}
