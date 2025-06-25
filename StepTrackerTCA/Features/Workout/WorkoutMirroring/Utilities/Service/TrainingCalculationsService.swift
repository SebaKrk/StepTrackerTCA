//
//  TrainingCalculationsService.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import Foundation
import SharedModels

protocol TrainingCalculationsService {
    
    ///
    func calculateMaxHeartRate(age: Int, gender: Gender?) -> Int
    
    ///
    func calculateHeartRateZone(current: Int, max: Int) -> HeartRateZone
    
    ///
    func calculateHeartRatePercentage(current: Int, max: Int) -> Int
    
}
