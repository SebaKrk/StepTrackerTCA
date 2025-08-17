//
//  WorkoutSummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 13/08/2025.
//

import ComposableArchitecture
import Commons
import SwiftUI
import SharedModels
import HealthKit

@ViewAction(for: WorkoutSummaryFeature.self)
struct WorkoutSummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutSummaryFeature>
    
    @State private var durationFormatter = DurationFormatter()
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                switch store.viewState {
                case .loading:
                    loadingView
                case .successfullyLoaded:
                    summaryView
                case .failed:
                    Text("failed")
                }
            }
            .toolbarRole(.navigationStack)
            .toolbar {
                // TODO: - Bład, powielajacy sie przycisk w tabBar
                toolbarButton
            }
            .toolbar(store.viewState == .loading ? .hidden : .visible, for: .navigationBar)
            .onAppear {
                send(.viewDidAppear)
            }
//            .onDisappear {
//                send(.viewDidDisappear)
//            }
        }
        .onAppear { print("WorkoutSummaryView appear") }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.endWorkoutButtonTapped)
            } label: {
                Image(systemName: "checkmark")
            }
            .foregroundStyle(.green)
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Saving workout")
            Spacer()
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var summaryView: some View {
            totalTime
            totalEnergy
            avgHeartRate
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
    
}


//        List {
//            HStack {
//                Image(systemName: "\(store.workoutSummary.workout.workoutConfiguration?.symbol ?? "figure.walk").circle.fill")
//                    .font(.title)
//                Text("\(store.workoutSummary.workout.workoutConfiguration?.name ?? "")")
//
//                SummaryMetricView(
//                    title: "Total Time",
//                    value: durationFormatter
//                        .string(from: store.workoutSummary.workout?.duration ?? 0.0) ?? ""
//                ).accentColor(Color.yellow)
//
//                if store.workoutSummary.workout?.workoutConfiguration.supportsDistance ?? false {
//                    SummaryMetricView(
//                        title: "Total Distance",
//                        value: Measurement(
//                            value: store.workoutSummary.workout?.totalDistance?
//                                .doubleValue(for: .meter()) ?? 0,
//                            unit: UnitLength.meters
//                        ).formatted(
//                            .measurement(
//                                width: .abbreviated,
//                                usage: .road
//                            )
//                        )
//                    ).accentColor(Color.blue)
//                }
//
//                SummaryMetricView(
//                    title: "Total Energy",
//                    value: Measurement(
//                        value: store.workoutSummary.workout?.statistics(for: .quantityType(forIdentifier: .activeEnergyBurned)!)?
//                            .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0,
//                        unit: UnitEnergy.kilocalories
//                    ).formatted(
//                        .measurement(
//                            width: .abbreviated,
//                            usage: .workout
//                        )
//                    )
//                ).accentColor(Color.pink)
//            }
//            .listStyle(.plain)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
//}

//struct SummaryMetricView: View {
//    var title: String
//    var value: String
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(title)
//                .font(.title2)
//            Text(value)
//                .font(.system(.title, design: .rounded)
//                    .lowercaseSmallCaps()
//                )
//                .foregroundColor(.accentColor)
//        }
//    }
//}

struct SummaryMetricView: View {
    
    // MARK: - Properties
    
    var title: String
    var value: String
    var valueColor: Color
    
    // MARK: - Lifecycle
    
    init(title: String, value: String, _ valueColor: Color) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    // MARK: - View
    
    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
            .foregroundStyle(valueColor)
        Divider()
    }
}
