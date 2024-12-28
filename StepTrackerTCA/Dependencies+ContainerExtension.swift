//
//  Dependencies+ContainerExtension.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import Factory
import Foundation

/// Container for application dependencies.
///
/// This extension provides a centralized place for registering and resolving
/// dependencies used across the application.
extension Container {
    
    /// A factory that provides a singleton instance of the `HealthKitManager`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultHealthKitManager`.
    /// - This ensures that the same instance of `HealthKitManager` is used throughout the application.
    var healthKitManager: Factory<HealthKitManager> {
        Factory(self) { DefaultHealthKitManager() }.singleton
    }
    
}
