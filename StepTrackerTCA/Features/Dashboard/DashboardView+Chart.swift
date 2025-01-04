//
//  DashboardView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 04/01/2025.
//

import Charts
import SwiftUI

extension DashboardView {

    @ViewBuilder
    var stepChart: some View {
        Chart {
            ForEach(store.stepData) { steps in
                BarMark(
                    x: .value("Date", steps.date, unit: .day),
                    y: .value("Steps", steps.value)
                )
            }
        }
        .frame(height: 150)
        .foregroundStyle(.pink)
    }
    
}
