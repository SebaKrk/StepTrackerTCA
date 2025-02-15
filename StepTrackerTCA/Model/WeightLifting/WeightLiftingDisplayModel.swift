//
//  WeightLiftingDisplayModel.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import Foundation

struct WeightLiftingDisplayModel: Identifiable {
    let id: String
    let movement: WeightliftingMovement
    let goal: Double
    let latestResult: Double
}
