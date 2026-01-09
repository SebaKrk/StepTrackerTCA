//
//  WorkoutLocationManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 06/01/2026.
//

import Foundation
import HealthKit
import CoreLocation

/// Manager for fetching workout location and route data.
///
/// Coordinates GPS data retrieval from HealthKit for workout routes and locations.
///
/// ## Architecture
/// ```
/// WorkoutLocationManager (this - location data fetching)
///         │
///         └── uses: HKHealthStore (route queries)
/// ```
///
/// ## Usage
/// ```swift
/// @Dependency(\.workoutLocationManager) var locationManager
///
/// let route = try await locationManager.fetchWorkoutRoute(workout)
/// let start = try await locationManager.fetchWorkoutStartLocation(workout)
/// ```
public protocol WorkoutLocationManager: Sendable {
    
    /// Fetches all GPS route points for a workout.
    ///
    /// Returns empty array if workout has no route data (indoor workout,
    /// GPS disabled, or workout type doesn't support routes).
    ///
    /// - Parameter workout: The workout to fetch route for
    /// - Returns: Array of location points in chronological order, or empty array
    func fetchWorkoutRoute(_ workout: HKWorkout) async throws -> [CLLocation]
    
    /// Fetches only the start location coordinate of a workout.
    ///
    /// Convenience method that fetches the route and returns first coordinate.
    /// Useful for displaying a single point on map without loading entire route.
    ///
    /// - Parameter workout: The workout to fetch start location for
    /// - Returns: Start coordinate, or nil if no route data available
    func fetchWorkoutStartLocation(_ workout: HKWorkout) async throws -> CLLocationCoordinate2D?
}


