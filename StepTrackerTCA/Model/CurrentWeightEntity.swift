//
//  CurrentWeightEntity.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation
//import SwiftData

//@Model
final class CurrentWeight { //Entity {
    
    // MARK: - Properties
    
//    @Attribute(.unique)
    var id: String
    
    /// The weight of the user.
    ///
    /// Stores the weight value as a `Double`. This is a required property
    /// that represents the user's weight at the time of recording.
    var weight: Double
    
    /// The date the weight was added.
    ///
    /// Stores the date as a `Date` object. This property indicates when the
    /// weight was recorded and is used for tracking purposes.
    var dateAdded: Date
    
    // MARK: - Lifecycle
    
    /// Initializes a new instance of `CurrentWeightEntity`.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the weight entity.
    ///   - weight: The weight of the user at the time of recording.
    ///   - dateAdded: The date the weight was recorded. Defaults to the current date and time
    ///     if no value is provided.
    init(id: String, weight: Double, dateAdded: Date) {
        self.id = id
        self.weight = weight
        self.dateAdded = dateAdded
    }
    
}
