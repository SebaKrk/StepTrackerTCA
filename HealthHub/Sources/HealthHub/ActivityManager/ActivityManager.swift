//
//  ActivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import HealthKit
import SharedModels

/// Manager for fetching and analyzing historical workout data.
public protocol ActivityManager: Sendable {
    
    /// Fetches a list of workouts from the specified time period.
    ///
    /// - Parameters:
    ///   - days: Number of days to look back from today
    ///   - option: Sort option to order results
    /// - Returns: Array of `HKWorkout` objects from the specified period
    /// - Throws: HealthKit errors if data access fails
    func fetchWorkouts(
        for days: Int,
        sortBy option: ActivitiesSortOption
    ) async throws -> [HKWorkout]
}
