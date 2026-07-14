//
//  HealthData.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/01/2025.
//

import Foundation

struct HealthData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}
