//
//  Dependencies+ContainerExtension.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Factory
import Foundation

/// Container for application dependencies.
///
/// This extension provides a centralized place for registering and resolving
/// dependencies used across the application.
extension Container {
    
    /// A factory that provides a singleton instance of the `WorkoutManager`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWorkoutManager`.
    /// - This ensures that the same instance of `WorkoutManager` is used throughout the application.
    var workoutManager: Factory<WorkoutManager> {
        Factory(self) { DefaultWorkoutManager() }.singleton
    }
    
}
