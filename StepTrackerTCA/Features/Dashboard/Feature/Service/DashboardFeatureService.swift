//
//  DashboardFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Foundation

/// Protocol defining operations for managing the state related to the step data permission screen.
protocol DashboardFeatureService {
    
    /// A property indicating whether the permission screen has been shown to the user.
    ///
    /// - Returns: `true` if the permission screen has already been displayed, `false` otherwise.
    var hasSeenPermissionPriming: Bool { get }
    
    /// Marks the permission screen as shown.
    ///
    /// - Saves this information in a persistent source, such as UserDefaults.
    func markPermissionPrimingAsSeen()
    
    /// Generates and saves mock HealthKit data for testing purposes.
    func getDummyData() async throws
    
}
