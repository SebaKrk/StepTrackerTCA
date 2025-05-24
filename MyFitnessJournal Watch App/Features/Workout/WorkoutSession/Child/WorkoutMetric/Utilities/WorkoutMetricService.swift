//
//  WorkoutMetricService.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation
import Factory
import SwiftUI

protocol WorkoutMetricService {
    
    func elapsedTime(at context: TimelineViewDefaultContext) -> TimeInterval?
    
}
