//
//  ElapsedTimeView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import SwiftUI

struct ElapsedTimeView: View {
    
    let elapsedTime: TimeInterval
    let showSubseconds: Bool
    
    @State private var timeFormatter = ElapsedTimeFormatter()
    
    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .fontWeight(.semibold)
            .onChange(of: showSubseconds) {
                timeFormatter.showSubseconds = showSubseconds
            }
            .onAppear {
                timeFormatter.showSubseconds = showSubseconds
            }
    }
}
