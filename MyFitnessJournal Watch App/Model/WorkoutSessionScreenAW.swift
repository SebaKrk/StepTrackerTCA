//
//  WorkoutSessionScreenAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

/// Enum representing the available screens (tabs) in the watch application when a workout session is running.
enum WorkoutSessionScreenAW: Codable, Hashable, Identifiable, CaseIterable {
    
    /// Screen for workout control actions (e.g. pause, resume, end).
    case controls
    
    /// Screen displaying live workout metrics (e.g. heart rate, distance).
    case workout
    
    /// Screen for media playback controls during a workout session.
    case nowPlaying
    
    /// Conformance to `Identifiable` using self as the ID.
    var id: Self { self }
    
}
