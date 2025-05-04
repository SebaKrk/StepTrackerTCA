//
//  ActivityFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Foundation
import HealthKit

protocol ActivityFeatureService {
    
    func getWorkoutData() async throws -> [HKWorkout]
    
}
