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
                switch store.healthMetric {
                case .steps:
                    groupBoxWalkView
                    groupBoxCalendarView
                case .weight:
                    groupBoxWeightView
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            
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
        GroupBox {
            stepChart
        } label: {
            NavigationLink(state: DashboardFeature.Path.State.healthDataListFeature(HealthDataListFeature.State(healthMetric: store.healthMetric))) {
                groupBoxTitle(
                    "Steps",
                    "figure.walk",
                    "Avg: \(Int(store.avgStepCount)) steps"
                )
            }
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var groupBoxCalendarView: some View {
        GroupBox {
            stepsPieChart
        } label: {
            groupBoxTitle("Averages",
                          "calendar",
                          "Last 28 Days",
                          destination: false)
        }
        .padding([.leading, .trailing], 8)
    }
    
    @ViewBuilder
    private var groupBoxWeightView: some View {
        GroupBox {
            weightLineChart
        } label: {
            NavigationLink(state: DashboardFeature.Path.State.healthDataListFeature(HealthDataListFeature.State(healthMetric: store.healthMetric))) {
                groupBoxTitle(
                    "Weight",
                    "figure",
                    "Avg: \(store.averageWeight) kg"
                )
            }
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private func groupBoxTitle(_ title: String, _ systemImage: String, _ secondaryText: String, destination: Bool = true) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(store.healthMetric == .steps ? .pink : .indigo)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if destination {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    @ViewBuilder
    var annotationView: some View {
        VStack(alignment: .leading) {
            Text(store.selectedHealthMetric?.date ?? .now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)

            Text(store.selectedHealthMetric?.value ?? 0, format: .number.precision(.fractionLength(0)))
                .fontWeight(.heavy)
                .foregroundStyle(.pink)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
    
    var weightAnnotationView: some View {
        VStack(alignment: .leading) {
            Text(store.selectedHealthMetric?.date ?? .now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)

            Text(store.selectedHealthMetric?.value ?? 0, format: .number.precision(.fractionLength(1)))
                .fontWeight(.heavy)
                .foregroundStyle(.indigo)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
    
    @ViewBuilder
    func pieTextView(_ title: String, _ value: Double) -> some View {
        VStack {
            Text(title)
                .font(.title3.bold())
                .contentTransition(.identity)
            
            Text(value, format: .number.precision(.fractionLength(0)))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
    }
}

#Preview {
    DashboardView(store: Store(initialState: DashboardFeature.State(), reducer: {
        DashboardFeature(service: DefaultDashboardFeatureService())
    }))
}
