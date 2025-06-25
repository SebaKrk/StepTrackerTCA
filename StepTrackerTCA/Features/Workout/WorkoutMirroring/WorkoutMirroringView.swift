//
//  WorkoutMirroringView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

import ComposableArchitecture
import SwiftUI
import HealthHub
import SharedModels
import Commons

@ViewAction(for: WorkoutMirroringFeature.self)
struct WorkoutMirroringView: View {
    @Bindable var store: StoreOf<WorkoutMirroringFeature>
    
    var body: some View {
        Group {
            if store.sessionState {
                activeWorkoutView
                    .animation(.easeInOut(duration: 0.5), value: store.currentHeartRateZone)
            } else {
                noActiveWorkoutView
            }
        }
        .toolbar {
            toolbarButton
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            send(.viewDidAppear)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false 
            send(.viewWillDisappear)
        }
        .sheet(item: $store.scope(state: \.destination?.openHeartRateZoneInfo,
                                  action: \.destination.openHeartRateZoneInfo)) { store in
            HeartRateZoneInfoView(store: store)
                .presentationDetents([.medium, .large])
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.heartRateZoneButtonTapped)
            } label: {
                Image(systemName: "heart.text.clipboard")
            }
        }
    }
    
    private var noActiveWorkoutView: some View {
        Text("Waiting for Watch workout...")
    }
    
    private var activeWorkoutView: some View {
        GroupBox {
            VStack {
                heartRateView
                Spacer().frame(height: 25)
                currentHeartRatePercentageView
                Spacer().frame(height: 25)
                activeEnergyBurnedView
            }
            Spacer().frame(height: 25)
            currentHeartRateZoneView
        }
        .padding()
    }
    
    private var heartRateView: some View {
        HStack {
            Group {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                
                Text(store.workoutMetrics.heartRate.formatted(.number.precision(.fractionLength(0))))
                Text("BPM")
            }
            .font(.system(.title3, design: .rounded).monospacedDigit())
            .foregroundColor(.primary)
            Spacer()
            
            Text(store.currentHeartRateZone.rawValue)
                .font(.title3.weight(.semibold))
                .foregroundColor(store.currentHeartRateZone.color)
        }
    }
    
    private var currentHeartRatePercentageView: some View {
        VStack(spacing: 5) {
            Text("\(store.currentHeartRatePercentage)%")
                .font(.system(size: 60))
//                .id(store.currentHeartRatePercentage)
//                .transition(.push(from: .bottom))
                .animation(.snappy(duration: 0.3), value: store.currentHeartRatePercentage)
        }
    }
        
    private var activeEnergyBurnedView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.pink)
                .font(.system(.title2, design: .rounded))
            Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundColor(.primary)
            Text("Active\nEnergy")
                .font(.system(.caption, design: .rounded).smallCaps())
        }
    }
    
    private var currentHeartRateZoneView: some View {
        HStack {
            Spacer()
            Text(store.currentHeartRateZone.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
}

#Preview("N/S") {
    NavigationStack {
        WorkoutMirroringView(store: Store(initialState: WorkoutMirroringFeature.State(), reducer: {
            WorkoutMirroringFeature()
        }))
    }
}

#Preview("Start") {
    NavigationStack {
        WorkoutMirroringView(store: Store(initialState: WorkoutMirroringFeature.State(
            workoutMetrics: WorkoutMetrics(
                averageHeartRate: 120,
                heartRate: 145,
                activeEnergy: 200
            ),
            sessionState: true,
            currentHeartRateZone: .anaerobic,
            currentHeartRatePercentage: 99,
        ), reducer: {
            WorkoutMirroringFeature()
        }))
    }
}
