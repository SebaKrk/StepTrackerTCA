//
//  CrossMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import Foundation

/// An enumeration representing different types of cross-training fitness goals.
///
/// This enum includes high-intensity exercises that test muscular endurance,
/// cardiovascular fitness, and explosive strength. Each case represents a timed
/// workout challenge commonly used in functional fitness training.
enum CrossMovement: String, Codable, MovementType {
    
    /// Pull-Ups - Measures upper-body endurance and grip strength.
    case pullUps
    
    /// Push-Ups - A benchmark for upper-body strength and endurance.
    case pushUps
    
    /// Burpees - A full-body endurance challenge.
    case burpees
    
    /// Air Squats - A lower-body endurance and mobility test.
    case airSquats
    
    /// Double-Unders - A test of coordination and cardiovascular endurance.
    case doubleUnders
    
    /// Box Jumps - A benchmark for lower-body power and explosiveness.
    case boxJumps

    /// A user-friendly title for each cross-training goal.
    ///
    /// This computed property returns a properly formatted string representation
    /// of the movement's name for UI display.
    var title: String {
        switch self {
        case .pullUps:
            return "Pull-Ups"
        case .pushUps:
            return "Push-Ups"
        case .burpees:
            return "Burpees"
        case .airSquats:
            return "Air Squats"
        case .doubleUnders:
            return "Double-Unders"
        case .boxJumps:
            return "Box Jumps"
        }
    }

    /// A description of the movement.
    ///
    /// This property provides a brief explanation of each challenge and its context.
    var description: String {
        switch self {
        case .pullUps:
            return "Perform as many pull-ups as possible in 1 minute to test upper-body endurance and grip strength."
        case .pushUps:
            return "Measure upper-body endurance by completing as many push-ups as possible within 1 minute."
        case .burpees:
            return "A full-body conditioning test; complete as many burpees as possible in 2 minutes."
        case .airSquats:
            return "Evaluate lower-body endurance by performing air squats for a full minute without stopping."
        case .doubleUnders:
            return "Perform as many double-unders as possible in 1 minute, testing coordination and cardio endurance."
        case .boxJumps:
            return "Measure explosive lower-body strength by completing as many box jumps as possible in 1 minute."
        }
    }
}
