//
//  StatsView+Components.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SwiftUI

extension StatsView {
    
    @ViewBuilder
    func trainingReadinessView() -> some View {
        TrainingReadinessView(store: store.scope(
            state: \.trainingReadiness,
            action: \.trainingReadiness)
        )
    }
    
    @ViewBuilder
    func testChart() -> some View {
        GroupBox {
            VStack {
                Spacer()
                Text("testChart")
                Spacer()
            }
            
        } label: {
            Text("Test")
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
        .frame(height: 250)
    }
    
}
