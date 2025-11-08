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
        IfLetStore(store.scope(state: \.trainingReadiness,
                               action: \.trainingReadiness)) { store in
            TrainingReadinessView(store: store)
        }
        //        if let store = store.scope(
        //            state: \.trainingReadiness,
        //            action: \.trainingReadiness
        //        ) {
        //            TrainingReadinessView(store: store)
        //        }
    }
    
    @ViewBuilder
    func summaryCards() -> some View {
        IfLetStore(store.scope(state: \.summaryCard,
                               action: \.summaryCard)) { store in
            HealthMetricSummaryCardView(store: store)
        }
        //        if let store = store.scope(
        //            state: \.summaryCard,
        //            action: \.summaryCard
        //        ) {
        //            HealthMetricSummaryCardView(store: store)
        //        }
    }
    
    @ViewBuilder
    func ringActivitiesSummaryView() -> some View {
        IfLetStore(store.scope(state: \.ringActivitiesSummary,
                               action: \.ringActivitiesSummary)) { store in
            RingActivitiesSummaryView(store: store)
        }
        //        if let store = store.scope(
        //            state: \.ringActivitiesSummary,
        //            action: \.ringActivitiesSummary
        //        ) {
        //            RingActivitiesSummaryView(store: store)
        //        }
        
    }
    
}
