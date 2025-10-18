//
//  HealthMetricSummaryDetailsCardView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: HealthMetricSummaryDetailsCardFeature.self)
struct HealthMetricSummaryDetailsCardView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthMetricSummaryDetailsCardFeature>
    
    // MARK: - Body
    
    var body: some View {
        Group {
            Text("HealthMetricSummaryDetailsCardFeature")
        }
        .navigationTitle("\(store.metricType.title) details")
    }
    
}
