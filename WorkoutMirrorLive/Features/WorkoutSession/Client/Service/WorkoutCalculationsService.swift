//
//  WorkoutCalculationsService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/08/2025.
//

import Foundation
import SharedModels

protocol WorkoutCalculationsService {
    
    ///
    func calculateMaxHeartRate(age: Int, gender: Gender?) -> Int
    
    ///
    func calculateHeartRateZone(current: Int, max: Int) -> HeartRateZone
    
    ///
    func calculateHeartRatePercentage(current: Int, max: Int) -> Int
    
}
