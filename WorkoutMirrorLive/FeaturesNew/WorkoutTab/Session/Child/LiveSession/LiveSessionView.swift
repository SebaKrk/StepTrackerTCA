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
                
                // Stopwatch view (if visible)
                if store.stopwatch.isVisible {
                    stopwatchView
                }

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
    
    // MARK: - Stopwatch View
    
    private var stopwatchView: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Time display
                Text(formatStopwatchTime(store.stopwatch.time))
                    .font(.system(size: 48, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.orange)
                
                // Control buttons
                HStack(spacing: 20) {
                    // Reset button (only when stopped and time > 0)
                    if !store.stopwatch.isRunning && store.stopwatch.time > 0 {
                        Button(action: {
                            send(.stopwatch(.reset))
                        }) {
                            Text("Reset")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    
                    // Start/Stop button
                    Button(action: {
                        send(.stopwatch(store.stopwatch.isRunning ? .stop : .start))
                    }) {
                        Text(store.stopwatch.isRunning ? "Stop" : "Start")
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(minWidth: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .inset(by: -10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            }
        }
    }
    
    // Helper - format stopwatch time
    private func formatStopwatchTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }

}

#Preview("LiveSessionFeature") {
    NavigationStack {
        LiveSessionView(
            store: Store(initialState: LiveSessionFeature.State(),
                         reducer: { LiveSessionFeature() })
        )
    }
}
