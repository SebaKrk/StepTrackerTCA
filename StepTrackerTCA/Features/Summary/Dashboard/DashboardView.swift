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
        Group {
            if store.stepData.isEmpty && store.weightData.isEmpty {
                ProgressView()
            } else {
                dashboardView
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Subview
    
    @ViewBuilder
    private var dashboardView: some View {
        NavigationStack {
            ScrollView {
                healthMetricContextPicker
                switch store.healthMetric {
                case .steps:
                    groupBoxWalkView
                    groupBoxCalendarView
                case .weight:
                    groupBoxWeightView
                    groupBoxWeightDiffView
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(store.healthMetric == .steps ? .pink : .indigo)
        .onAppear {
            send(.viewDidAppear)
        }
        .refreshable {
            send(.userPulledToRefresh)
        }
        .sheet(item: $store.scope(state: \.destination?.openHealthKitPermissionScreen,
                                  action: \.destination.openHealthKitPermissionScreen)) { store in
            HealthKitPermissionPrimingView(store: store)
        }
    }
    
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
        StepWidgetView(store: store.scope(state: \.stepWidget, action: \.stepWidget))
    }
    
    @ViewBuilder
    private var groupBoxCalendarView: some View {
        StepPieWidgetView(store: store.scope(state: \.stepPieWidget, action: \.stepPieWidget))
    }
    
    @ViewBuilder
    private var groupBoxWeightView: some View {
        WeightGoalWidgetView(store: store.scope(state: \.weightGoalWidget, action: \.weightGoalWidget))
    }
    
    @ViewBuilder
    private var groupBoxWeightDiffView: some View {
        WeightDiffWidgetView(store: store.scope(state: \.weightDiffWidget, action: \.weightDiffWidget))
    }

}

#Preview {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(stepData: MockData.steps, weightData: MockData.weights), reducer: {
            DashboardFeature(service: DefaultDashboardFeatureService())
        }))
    }
}
