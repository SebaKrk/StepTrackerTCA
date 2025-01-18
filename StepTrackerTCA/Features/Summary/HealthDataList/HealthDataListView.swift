//
//  HealthDataListView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: HealthDataListFeature.self)
struct HealthDataListView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthDataListFeature>
    
    // MARK: - View
    
    var body: some View {
        if let healthMetric = store.healthMetric {
            List(Array(store.healthData.reversed())) { data in
                testCell(data)
            }
            .navigationTitle(healthMetric.title)
            .sheet(item: $store.scope(state: \.destination?.openAddMetricData,
                                      action: \.destination.openAddMetricData)) { store in
                AddMetricDataView(store: store)
            }
            .toolbar {
                toolbarButton
            }
        } else {
            ProgressView()
        }
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var toolbarButton: some View {
        Button {
            send(.addDataButtonPressed)
        } label: {
            Label("Add data", systemImage: "plus")
        }
    }
    
    @ViewBuilder
    private func testCell(_ data: HealthData) -> some View {
        HStack {
            Text(data.date, format: .dateTime.month().day().year())
            Spacer()
            Text(data.value, format: .number.precision(.fractionLength(store.healthMetric == .steps ? 0 : 1)))
        }
    }
    
}
