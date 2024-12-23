//
//  AddMetricDataView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddMetricDataFeature.self)
struct AddMetricDataView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AddMetricDataFeature>
    
    // MARK: - View
    
    var body: some View {
        if let healthMetric = store.healthMetric {
            NavigationStack {
                VStack {
                    Text(healthMetric.title)
                }
                .navigationTitle(healthMetric.title)
                .toolbar {
                    toolbarButton
                }
            }
        } else {
            ProgressView()
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.addDataButtonPressed)
            } label: {
                Text("Add Data")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.dismissButtonPressed)
            } label: {
                Text("Dismiss")
            }
        }
    }
    
}
