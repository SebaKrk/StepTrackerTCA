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
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<RingActivitiesSummaryDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .padding([.leading, .trailing], 8)
            .background(LinearGradient(colors: [store.color.opacity(0.10), .clear],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .navigationTitle("Activities Details")
            .onAppear {
                send(.viewDidAppear)
            }

    }
    
    private var rootView: some View {
        ScrollView {
            VStack(spacing: 16) {
                moveGroupBox
                exerciseGroupBox
                standGroupBox
                hourlyActivityAnnotationView
                // TODO: - Dodac funckinolnosc zaznaczania na wykresach danej jedenj godziny i wyswietlenia statystki z tej wlasnie godziny
//                if selected hour {
//                    hourlyActivityAnnotationView
//                }
            }
        }
    }
    
    // MARK: - Move (Active Energy)
    
    private var moveGroupBox: some View {
        GroupBox {
            HourlyActivityChart(
                hourlyData: store.hourlyData,
                dataType: .move,
                totalValue: store.activityRingData.moveValue,
                goalValue: store.activityRingData.moveGoal
            )
        } label: {
            VStack {
                HStack {
                    Text("W ruchu")
                        .foregroundColor(.pink)
                    Spacer()
                    Text("\(Int(store.activityRingData.moveValue))/\(Int(store.activityRingData.moveGoal)) kcal")
                        .foregroundColor(.gray)
                    
                }
                .font(.caption)
                Divider()
            }
        }
        .skeleton(isLoading: store.viewState == .loading)
        .styledGroupBox()
    }
    
    // MARK: - Exercise
    
    private var exerciseGroupBox: some View {
        GroupBox {
            HourlyActivityChart(
                hourlyData: store.hourlyData,
                dataType: .exercise,
                totalValue: store.activityRingData.exerciseValue,
                goalValue: store.activityRingData.exerciseGoal
            )
        } label: {
            VStack {
                HStack {
                    Text("Ćwiczenie")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(Int(store.activityRingData.exerciseValue))/\(Int(store.activityRingData.exerciseGoal)) min")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                Divider()
            }
        }
        .skeleton(isLoading: store.viewState == .loading)
        .styledGroupBox()
    }
    
    // MARK: - Stand Hours
    
    private var standGroupBox: some View {
        GroupBox {
            HourlyActivityChart(
                hourlyData: store.hourlyData,
                dataType: .stand,
                totalValue: store.activityRingData.standValue,
                goalValue: store.activityRingData.standGoal
            )
        } label: {
            VStack {
                HStack {
                    Text("Na nogach")
                        .foregroundColor(.cyan)
                    Spacer()
                    Text("\(Int(store.activityRingData.standValue))/\(Int(store.activityRingData.standGoal)) godz.")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                Divider()
            }
        }
        .skeleton(isLoading: store.viewState == .loading)
        .styledGroupBox()
    }
    
    var hourlyActivityAnnotationView: some View {
        let data = HourlyActivityData(hour: 5, activeEnergyBurned: 32, exerciseMinutes: 22, standHours: 1, date: .now)
        return GroupBox {
            activityView(data)
        }
        .styledGroupBox()
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
    
    private func activityView(_ data: HourlyActivityData) -> some View {
        VStack {
            // Header z godziną
            HStack {
                Spacer()
                Text("\(String(format: "%02d:00", data.hour))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Divider()
            
            // Metryki w poziomie
            HStack(spacing: 0) {
                activityMetric(
                    title: "W ruchu",
                    value: Int(data.activeEnergyBurned),
                    unit: "kcal",
                    color: .pink
                )
                
                Divider()
                    .frame(height: 40)
                
                activityMetric(
                    title: "Ćwiczenie",
                    value: Int(data.exerciseMinutes),
                    unit: "min",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                activityMetric(
                    title: "Na nogach",
                    value: data.standHours,
                    unit: data.standHours == 1 ? "tak" : "nie",
                    color: .cyan
                )
            }
        }
        .font(.subheadline)
        .padding(.vertical, 4)
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


