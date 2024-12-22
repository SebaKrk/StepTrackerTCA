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
        List(0..<28) { i in
            testCell()
        }
        .navigationTitle(store.healthMetric.title)
        .sheet(item: $store.scope(state: \.destination?.openAddMetricData,
                                  action: \.destination.openAddMetricData)) { store in
            AddMetricDataView(store: store)
        }
        .toolbar {
            toolbarButton
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
    private func testCell() -> some View {
        HStack {
            Text(Date(), format: .dateTime.month().day().year())
            Spacer()
            Text(10000, format: .number.precision(.fractionLength(store.healthMetric == .steps ? 0 : 1)))
        }
    }
    
}
