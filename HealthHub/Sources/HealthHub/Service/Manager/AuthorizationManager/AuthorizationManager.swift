//
//  AuthorizationManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

/// A protocol that defines the interface for managing HealthKit authorization.
public protocol AuthorizationManager: Sendable {
    
    /// Requests authorization from HealthKit to read and/or write the required data types.
    func requestAuthorization()
}
