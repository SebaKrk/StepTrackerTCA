//
//  DefaultWorkoutLocationManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 06/01/2026.
//

import Foundation
import HealthKit
import CoreLocation

public final class DefaultWorkoutLocationManager: WorkoutLocationManager, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    
    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Public Methods
    
    public func fetchWorkoutRoute(_ workout: HKWorkout) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            let routeType = HKSeriesType.workoutRoute()
            let predicate = HKQuery.predicateForObjects(from: workout)
            
            let routeQuery = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] query, samples, error in
                
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                if let error = error {
                    print("⚠️ WorkoutLocationManager: Failed to fetch route samples - \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let routes = samples as? [HKWorkoutRoute],
                      let route = routes.first else {
                    // No route data available - not an error, just return empty
                    print("ℹ️ WorkoutLocationManager: No route data for workout")
                    continuation.resume(returning: [])
                    return
                }
                
                // Fetch location points from route
                var locations: [CLLocation] = []
                
                let locationQuery = HKWorkoutRouteQuery(route: route) { _, newLocations, done, error in
                    
                    if let error = error {
                        print("⚠️ WorkoutLocationManager: Failed to fetch location points - \(error)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let newLocations = newLocations {
                        locations.append(contentsOf: newLocations)
                    }
                    
                    if done {
                        print("✅ WorkoutLocationManager: Fetched \(locations.count) location points")
                        continuation.resume(returning: locations)
                    }
                }
                
                self.healthStore.execute(locationQuery)
            }
            
            healthStore.execute(routeQuery)
        }
    }
    
    public func fetchWorkoutStartLocation(_ workout: HKWorkout) async throws -> CLLocationCoordinate2D? {
        let route = try await fetchWorkoutRoute(workout)
        return route.first?.coordinate
    }
    
}
