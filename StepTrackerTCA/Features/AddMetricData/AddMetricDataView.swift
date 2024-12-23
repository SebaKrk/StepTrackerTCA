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
                formView(healthMetric)
                .navigationTitle(healthMetric.title)
                .toolbar {
                    toolbarButton
                }
                .alert(store: store.scope(state: \.$alert, action: \.alert))
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
    
    @ViewBuilder
    private func formView(_ healthMetric: HealthMetricContext) -> some View {
        VStack {
            Form {
                datePicker
                metricTextField(healthMetric)
            }
        }
    }
    
    @ViewBuilder
    var datePicker: some View {
        DatePicker("Date", selection: $store.addDataDate, displayedComponents: .date)
    }
    
    @ViewBuilder
    private func metricTextField(_ healthMetric: HealthMetricContext) -> some View {
        HStack {
            Text(healthMetric.title)
            Spacer()
            TextField("Value", text: $store.valueToAdd)
                .multilineTextAlignment(.trailing)
                .frame(width: 140)
                .keyboardType(healthMetric == .steps ?.numberPad : .decimalPad)
        }
    }
    
} 
