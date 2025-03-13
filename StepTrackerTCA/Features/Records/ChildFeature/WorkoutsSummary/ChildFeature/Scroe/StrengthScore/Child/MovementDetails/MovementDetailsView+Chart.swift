//
//  MovementDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import Charts
import SwiftUI

extension MovementDetailsView {
    
    func createPointMark(with data: WorkoutStrength) -> some ChartContent {
        PointMark(
            x: .value("Day", data.date, unit: .day),
            y: .value("Value", data.value)
        )
        .foregroundStyle(.green)
        .interpolationMethod(.catmullRom)
        .symbol(.circle)
    }
    
}
