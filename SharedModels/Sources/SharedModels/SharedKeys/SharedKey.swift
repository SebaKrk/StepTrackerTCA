//
//  SharedKeys.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import Foundation

extension String {
    
    /// Subscription tier storage key
    public static var subscriptionTier: String {
        AppStorageKeys.subscriptionTier
    }
    
    /// Readiness level color
    public static var readinessLevelColor: String {
        AppStorageKeys.readinessLevelColor
    }

    /// Quick picker workouts (user-configurable visible subset of WorkoutType)
    public static var quickPickerWorkouts: String {
        AppStorageKeys.quickPickerWorkouts
    }

}
