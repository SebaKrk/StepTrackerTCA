//
//  SplashFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SplashFeature` state
extension SplashFeature {
    @ObservableState
    struct State: Equatable {
        
        /// Indicates whether the splash screen is active and the main app should be shown.
        var isActive: Bool = false
    }
    
}
