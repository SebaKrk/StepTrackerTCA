//
//  ActivityRingsSummaryView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/06/2025.
//

import ComposableArchitecture
import HealthKit
import SwiftUI

struct ActivityRingsSummaryView: View {
    
    let ringData: ActivityRingData?
    
    var body: some View {
        HStack {
            if let ringData = ringData {
                ActivityRingsView(ringData: ringData)
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: "%.0f/%.0f", ringData.moveValue, ringData.moveGoal))
                        .foregroundColor(.pink)
                    Text(String(format: "%.0f/%.0fM", ringData.exerciseValue, ringData.exerciseGoal))
                        .foregroundColor(.green)
                    Text(String(format: "%.0f/%.0fH", ringData.standValue, ringData.standGoal))
                        .foregroundColor(.cyan)
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                Spacer()
            } else {
                Text("No data available")
            }
            
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
}
