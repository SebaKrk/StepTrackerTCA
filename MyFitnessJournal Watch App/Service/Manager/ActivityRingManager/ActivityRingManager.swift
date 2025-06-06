//
//  ActivityRingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/06/2025.
//

import Foundation

/// A protocol that defines the interface for managing and retrieving activity ring data.
/// Implementers of this protocol are responsible for fetching activity summaries,
/// typically representing the user's physical activity for the current day.
protocol ActivityRingManager {
    
    /// Fetches the activity summary for the current day.
    ///
    /// - Returns: An `ActivityRingData` object containing the user's activity information for today.
    /// - Throws: An error if the data retrieval fails or is unavailable.
    func fetchTodaySummary() async throws -> ActivityRingData
}
