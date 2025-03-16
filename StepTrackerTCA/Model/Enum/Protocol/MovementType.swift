//
//  MovementType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/03/2025.
//

import Foundation

/// A protocol representing a type of movement in a workout.
///
/// This protocol is implemented by different movement categories such as
/// `WeightliftingMovement`, `StrengthMovement`, `FitnessMovement`, etc.
/// It enforces a `title` property, which provides a user-friendly name for each movement.
/// It also includes an `icon` property for visual representation and a `description` property
/// to explain the movement's purpose.
///
/// - Conforms to: `CaseIterable`, `RawRepresentable`
protocol MovementType: CaseIterable, RawRepresentable where RawValue == String {
    
    /// The user-friendly name of the movement.
    ///
    /// Each movement type must provide a readable name that can be displayed in the UI.
    var title: String { get }
    
    /// The icon representing the movement.
    ///
    /// Each movement type should provide an icon that visually represents it.
    var icon: String { get }
    
    /// A description of the movement.
    ///
    /// Each movement type must provide a readable description explaining its purpose.
    var description: String { get }
}
