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
        if let store = store.scope(
            state: \.trainingReadiness,
            action: \.trainingReadiness
        ) {
            TrainingReadinessView(store: store)
        }
    }
    
    @ViewBuilder
    func summaryCards() -> some View {
        if let store = store.scope(
            state: \.summaryCard,
            action: \.summaryCard
        ) {
            HealthMetricSummaryCardView(store: store)
        }
    }
    
    @ViewBuilder
    func ringActivitiesSummaryView() -> some View {
        if let store = store.scope(
            state: \.ringActivitiesSummary,
            action: \.ringActivitiesSummary
        ) {
            RingActivitiesSummaryView(store: store)
        }
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
