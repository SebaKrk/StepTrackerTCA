//
//  DashboardViewState.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/01/2025.
//

import Foundation

/// The view state that components can take in `Application`
enum DashboardViewState {
    
    /// The state in which the view reads the relevant information necessary for it to function correctly.
    case loading
    
    /// The state when the view is correctly loaded and displays the relevant content.
    case successfullyLoaded
    
    ///
    case noContentAvailable
    
    /// Error has occurred when loading the view.
    case failed
}
