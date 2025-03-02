//
//  WeightGoal.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/02/2025.
//

import Foundation

struct WeightGoal: Identifiable, Equatable {
    
    var id: String
    
    var weight: Double
    
    var weightUnit: WeightUnit
    
    var dateAdded: Date
    
    init(id: String, weight: Double, weightUnit: WeightUnit, dateAdded: Date) {
        self.id = id
        self.weight = weight
        self.weightUnit = weightUnit
        self.dateAdded = dateAdded
    }
    
}
