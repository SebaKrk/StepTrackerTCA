//
//  RingActivitiesSummaryDetailsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 19/10/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI
import Charts

@ViewAction(for: RingActivitiesSummaryDetailsFeature.self)
struct RingActivitiesSummaryDetailsView: View {
    
    @Bindable var store: StoreOf<RingActivitiesSummaryDetailsFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    activityGroupBox(
                        type: .move,
                        title: "W ruchu",
                        value: store.activityRingData.moveValue,
                        goal: store.activityRingData.moveGoal
                    )
                    
                    activityGroupBox(
                        type: .exercise,
                        title: "Ćwiczenie",
                        value: store.activityRingData.exerciseValue,
                        goal: store.activityRingData.exerciseGoal
                    )
                    
                    activityGroupBox(
                        type: .stand,
                        title: "Na nogach",
                        value: store.activityRingData.standValue,
                        goal: store.activityRingData.standGoal
                    )
                    
                    if let selectedHour = store.selectedHour,
                       let selectedData = store.hourlyData.first(where: { $0.hour == selectedHour }) {
                        hourlyDetailsView(for: selectedData)
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(
                LinearGradient(
                    colors: [store.color.opacity(0.10), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Activities Details")
            .onAppear {
                send(.viewDidAppear)
            }
        }
    }
    
    // MARK: - Activity Group Box

    @ViewBuilder
    private func activityGroupBox(
        type: ActivityChartView.ActivityType,
        title: String,
        value: Double,
        goal: Double
    ) -> some View {
        GroupBox {
            if store.viewState == .loading {
                Text("placeholder")
                    .frame(height: 90)
            } else {
                ActivityChartView(
                    hourlyData: store.hourlyData,
                    selectedHour: store.selectedHour,
                    activityType: type,
                    onHourSelected: { hour in
                        store.selectedHour = hour
                    }
                )
            }
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .foregroundColor(type.color)
                    Spacer()
                    Text("\(Int(value))/\(Int(goal)) \(type.unit)")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                Divider()
            }
        }
        .skeleton(isLoading: store.viewState == .loading)
        .styledGroupBox()
    }
    
    // MARK: - Hourly Details View
    
    private func hourlyDetailsView(for data: HourlyActivityData) -> some View {
        GroupBox {
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Text(String(format: "%02d:00", data.hour))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack(spacing: 0) {
                    activityMetric(
                        title: "W ruchu",
                        value: Int(data.activeEnergyBurned),
                        unit: "kcal",
                        color: .pink
                    )
                    
                    Divider().frame(height: 40)
                    
                    activityMetric(
                        title: "Ćwiczenie",
                        value: Int(data.exerciseMinutes),
                        unit: "min",
                        color: .green
                    )
                    
                    Divider().frame(height: 40)
                    
                    activityMetric(
                        title: "Na nogach",
                        value: data.standHours,
                        unit: data.standHours == 1 ? "tak" : "nie",
                        color: .cyan
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .styledGroupBox()
        .transition(.scale.combined(with: .opacity))
    }
    
    private func activityMetric(
        title: String,
        value: Int,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

}
