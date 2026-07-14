//
//  WorkoutCategory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/03/2025.
//
import Foundation

/// A protocol representing different categories of workouts.
///
/// This protocol is intended to be implemented by different workout categories,
/// such as `CardioWorkout`, `StrengthWorkout`, or `FlexibilityWorkout`.
/// It enforces properties that define the category's title, description,
/// and the associated movement type.
///
/// - Conforms to: `CaseIterable`, `RawRepresentable`
/// - Requires: `RawValue` to be a `String`
protocol WorkoutCategory: CaseIterable, RawRepresentable where RawValue == String {
    
    /// The title of the workout category.
    ///
    /// Each workout category must provide a readable name that can be displayed in the UI.
    var title: String { get }
    
    /// A description of the workout category.
    ///
    /// Each workout category should provide an informative description to help users
    /// understand its purpose.
    var description: String { get }
    
    /// The type of movement associated with the workout category.
    ///
    /// Each category is linked to a specific type of movement, such as strength training
    /// or aerobic exercises. The associated type must conform to `MovementType`.
    var movementType: any MovementType.Type { get }
}
