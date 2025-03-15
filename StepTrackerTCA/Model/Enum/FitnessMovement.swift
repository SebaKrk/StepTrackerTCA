//
//  FitnessMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different types of fitness goals.
///
/// This enum includes endurance-based activities, providing a structured way
/// to categorize and track fitness-related performance goals.
enum FitnessMovement: String, Codable, MovementType {
    
    /// Running 5 km - A common distance goal for beginner and intermediate runners.
    case run5km
    
    /// Running 15 km - A long-distance endurance challenge for experienced runners.
    case run15km
    
    /// Sprinting 400 m - A short-distance high-intensity running goal.
    case sprint400m
    
    /// Swimming 1 km - A standard training distance for swimming endurance.
    case swim1km
    
    /// Cycling 20 km - A moderate endurance distance for beginner and intermediate cyclists.
    case ride20km
    
    /// Rowing 2 km - A classic benchmark test for rowing endurance and power output.
    case row2km

    /// A user-friendly title for each fitness movement.
    ///
    /// This computed property returns a properly formatted string representation
    /// of the movement's name for UI display.
    var title: String {
        switch self {
        case .run5km:
            return "Run 5 km"
        case .run15km:
            return "Run 15 km"
        case .sprint400m:
            return "Sprint 400 m"
        case .swim1km:
            return "Swim 1 km"
        case .ride20km:
            return "Ride 20 km"
        case .row2km:
            return "Row 2 km"
        }
    }

    /// A description of the movement.
    ///
    /// This property provides a brief explanation of each exercise goal.
    var description: String {
        switch self {
        case .run5km:
            return "A popular running goal that builds endurance and cardiovascular health."
        case .run15km:
            return "A challenging long-distance run requiring stamina and pacing control."
        case .sprint400m:
            return "A high-intensity short-distance sprint that tests speed and anaerobic capacity."
        case .swim1km:
            return "A standard distance for swim training, improving endurance and technique."
        case .ride20km:
            return "A solid cycling distance for improving leg strength and cardiovascular endurance."
        case .row2km:
            return "A classic rowing distance for testing endurance, often used in competitions."
        }
    }

    /// A system symbol representing the movement.
    ///
    /// This computed property returns an appropriate SF Symbol for each fitness activity,
    /// helping to visually distinguish different exercises in the user interface.
    var icon: String {
        switch self {
        case .run5km:
            return "figure.run"
        case .run15km:
            return "figure.run.circle"
        case .sprint400m:
            return "figure.sprint"
        case .swim1km:
            return "figure.swim"
        case .ride20km:
            return "bicycle.circle"
        case .row2km:
            return "figure.rower"
        }
    }
}
