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
    
}


