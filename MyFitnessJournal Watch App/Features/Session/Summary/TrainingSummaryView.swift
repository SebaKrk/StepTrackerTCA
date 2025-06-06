//
//  TrainingSummaryView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 30/05/2025.
//

import ComposableArchitecture
import SwiftUI
import HealthKit

@ViewAction(for: TrainingSummaryFeature.self)
struct TrainingSummaryView: View {
    
    @Dependency(\.healthStore) var healthStore
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingSummaryFeature>
    
    @State private var durationFormatter = DurationFormatter()
    
    // MARK: - View
    
    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
            case .successfullyLoaded:
                trainingSummaryView
            case .failed:
                Text("failed")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - SubView
    
    private var trainingSummaryView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                totalTime
                totalEnergy
                avgHeartRate
                activityRingsView
            }
            doneButton
        }
    }
    
    private var totalTime: some View {
        SummaryMetricView(title: "Total Time",
                          value: durationFormatter.string(for: store.summary?.workout?.duration) ?? "00:00:00", .yellow)
    }
    
    private var totalEnergy: some View {
        let energyFromWorkout = store.summary?.workout?
            .statistics(for: .init(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie())
        
        let energyFromMetrics = store.summary?.metrics.activeEnergy
        
        let finalEnergy = energyFromWorkout ?? energyFromMetrics ?? 0
        
        return SummaryMetricView(
            title: "Total Energy",
            value: Measurement(value: finalEnergy, unit: UnitEnergy.kilocalories)
                .formatted(.measurement(
                    width: .abbreviated,
                    usage: .workout,
                    numberFormatStyle: .number.precision(.fractionLength(0))
                )),
            .pink
        )
    }
    
    private var avgHeartRate: some View {
        SummaryMetricView(
            title: "Avg. Heart Rate",
            value: (store.summary?.metrics.averageHeartRate.formatted(.number.precision(.fractionLength(0))) ?? "--") + " bpm",
            .red
        )
    }
    
    private var activityRingsView: some View {
        VStack(alignment: .leading) {
            Text("Activity Rings")
                .foregroundStyle(.foreground)
            ActivityRingsSummaryView(ringData: store.activityRingData)
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            send(.doneButtonPressed)
        }
    }
    
}

#Preview {
    TrainingSummaryView(store: Store(initialState: TrainingSummaryFeature.State(), reducer: {
        TrainingSummaryFeature()
    }))
}
