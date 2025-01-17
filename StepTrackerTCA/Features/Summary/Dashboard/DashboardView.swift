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
        let service = DefaultStepWidgetService()
        StepWidgetView(store: Store(initialState: StepWidgetFeature.State(stepData: store.stepData), reducer: {
            StepWidgetFeature(service: service)
        }))
    }
    
    @ViewBuilder
    private var groupBoxCalendarView: some View {
        let service = DefaultStepPieWidget()
        StepPieWidgetView(store: Store(initialState: StepPieWidgetFeature.State(stepData: store.stepData), reducer: {
            StepPieWidgetFeature(service: service)
        }))
    }
    
    @ViewBuilder
    private var groupBoxWeightView: some View {
        let service = DefaultWeightGoalWidgetService()
        WeightGoalWidgetView(store: Store(initialState: WeightGoalWidgetFeature.State(weightData: store.weightData), reducer: {
            WeightGoalWidgetFeature(service: service)
        }))
    }
    
    @ViewBuilder
    private var groupBoxWeightDiffView: some View {
        let service = DefaultWeightDiffService()
        WeightDiffWidgetView(store: Store(initialState: WeightDiffWidgetFeature.State(weightData: store.weightData), reducer: {
            WeightDiffWidgetFeature(service: service)
        }))
    }

}

#Preview {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(stepData: MockData.steps, weightData: MockData.weights), reducer: {
            DashboardFeature(service: DefaultDashboardFeatureService())
        }))
    }
}
