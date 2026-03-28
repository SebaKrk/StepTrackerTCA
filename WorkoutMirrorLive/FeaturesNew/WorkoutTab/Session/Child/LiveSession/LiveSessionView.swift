//
//  LiveSessionView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Commons
import SwiftUI
import SharedModels

@ViewAction(for: LiveSessionFeature.self)

struct LiveSessionView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<LiveSessionFeature>
    
    // MARK: - Body
    
    var body: some View {
            ScrollView {
                HStack {
                    secondaryMetricCard("avg hr",
                                        data: store.sessionAverageHeartRate)
                    secondaryMetricCard("max hr",
                                        data: store.sessionMaxHeartRate)
                }
                workoutMetricsCard
                
                if store.userStopwatch.isVisible {
                    StopwatchView(store: store.scope(state: \.userStopwatch, action: \.userStopwatch))
                }

                if store.phaseStopwatch.isManagingPhase {
                    StopwatchView(store: store.scope(state: \.phaseStopwatch, action: \.phaseStopwatch))
                }

                phasePanelSection

                Spacer()
            }
            .padding([.leading, .trailing], 8)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                send(.viewDidAppear)
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false}
    }
    
    // MARK: - SubView
    
    private var workoutMetricsCard: some View {
        GroupBox {
            VStack {
                heartRateView
                Spacer().frame(height: 10)
                currentHeartRatePercentageView
                activeEnergyBurnedView
                Spacer().frame(height: 10)
                currentHeartRateZoneView
            }
            .overlay {
                if store.currentHeartRateZone != .resting {
                    RoundedRectangle(cornerRadius: 2)
                        .inset(by: -10)
                        .stroke(store.currentHeartRateZone.color.opacity(0.3),
                                lineWidth: 1)
                }
            }
        }
    }
    
    private func secondaryMetricCard(_ title: String, data: Int) -> some View {
        GroupBox {
            VStack(spacing: 2) {
                Text(title)
                    .textCase(.uppercase)
                Text(data.formatted(.number))
                    .font(.largeTitle.bold())
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
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
            
            Text(store.currentHeartRateZone.title)
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
                .animation(.snappy(duration: 0.3), value: 70)
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
            }
    }
    
    // MARK: - Phase Panel

    @ViewBuilder
    private var phasePanelSection: some View {
        if !store.phaseStopwatch.isManagingPhase,
           let phasePanelStore = store.scope(state: \.phasePanel, action: \.phasePanel) {
            PhasePanelView(store: phasePanelStore)
                .frame(minHeight: 180)
        }
    }
    
}

#Preview("without plan") {
    NavigationStack {
        LiveSessionView(
            store: Store(initialState: LiveSessionFeature.State()) {
                LiveSessionFeature()
            }
        )
    }
}

#Preview("with stopwatch") {
    var state = LiveSessionFeature.State()
    state.userStopwatch.isVisible = true
    return NavigationStack {
        LiveSessionView(
            store: Store(initialState: state) {
                LiveSessionFeature()
            }
        )
    }
}

#Preview("with plan") {
    let phases = TrainingSession.previewTrainingSession.phases
    var state = LiveSessionFeature.State()
    state.phasePanel = PhasePanelFeature.State(phases: phases)
    return NavigationStack {
        LiveSessionView(
            store: Store(initialState: state) {
                LiveSessionFeature()
            }
        )
    }
}
