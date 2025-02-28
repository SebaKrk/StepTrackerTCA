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
    
    var dateAdded: Date
    
    init(id: String, weight: Double, dateAdded: Date) {
        self.id = id
        self.weight = weight
        self.dateAdded = dateAdded
    }
    
}
