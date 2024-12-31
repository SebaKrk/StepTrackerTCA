//
//  DashboardView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: DashboardFeature.self)
struct DashboardView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<DashboardFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                healthMetricContextPicker
                groupBoxWalkView
                groupBoxCalendarView
            }
            .navigationTitle("Dashboard")
            
        } destination: { store in
            switch store.case {
            case let .healthDataListFeature(store):
                HealthDataListView(store: store)
            }
        }
        .tint(store.healthMetric == .steps ? .pink : .indigo)
        .onAppear {
            send(.viewDidAppear)
        }
        .sheet(item: $store.scope(state: \.destination?.openHealthKitPermissionScreen,
                                  action: \.destination.openHealthKitPermissionScreen)) { store in
            HealthKitPermissionPrimingView(store: store)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private var healthMetricContextPicker: some View {
        Picker("HealthMetric", selection: $store.healthMetric.sending(\.selectedPickerChange)) {
            ForEach(HealthMetricContext.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 6)
    }
    
    @ViewBuilder
    private var groupBoxWalkView: some View {
        NavigationLink(state: DashboardFeature.Path.State.healthDataListFeature(HealthDataListFeature.State(healthMetric: store.healthMetric))) {
            GroupBox {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            } label: {
                groupBoxTitle(
                    "Steps",
                    "figure.walk",
                    "Avg: 10K Steps"
                )
            }
            .padding([.leading, .trailing], 8)
        }
        .foregroundStyle(.secondary)
        
    }
    
    @ViewBuilder
    private var groupBoxCalendarView: some View {
        GroupBox {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
                .frame(height: 240)
        } label: {
            groupBoxTitle("Averages",
                          "calendar",
                          "Last 28 Days",
                          destination: false)
        }
        .padding([.leading, .trailing], 8)
    }
    
    
    @ViewBuilder
    private func groupBoxTitle(_ title: String, _ systemImage: String, _ secondaryText: String, destination: Bool = true) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
                Text(secondaryText)
                    .font(.caption)
            }
            Spacer()
            if destination {
                Image(systemName: "chevron.right")
            }
        }
    }
}

#Preview {
    DashboardView(store: Store(initialState: DashboardFeature.State(), reducer: {
        DashboardFeature()
    }))
}
