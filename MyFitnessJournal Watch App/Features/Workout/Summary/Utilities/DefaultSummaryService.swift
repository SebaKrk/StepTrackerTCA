//
//  DefaultSummaryService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/05/2025.
//

import Factory
import Foundation

final class DefaultSummaryService: SummaryService {
        
    // MARK: - Dependency
    
    @Injected(\.workoutManager) private var workoutManager
    
    // MARK: - API
    
    func setShowingSummaryView(_ isShowing: Bool) {
        workoutManager.showingSummaryView = isShowing
    }

}
