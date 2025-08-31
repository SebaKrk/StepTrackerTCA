//
//  SummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Commons
import HealthKit
import SwiftUI
import SharedModels

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - View
    
    var body: some View {
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
        .onAppear {
            send(.viewDidAppear)
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
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let summary = store.summary, let workout = summary.workout {
                        WorkoutInfoRow(
                            title: "Typ aktywności",
                            value: workout.workoutActivityType.name
                        )
                        WorkoutInfoRow(
                            title: "Czas trwania",
                            value: workout.duration.formattedDuration()
                        )
                        WorkoutInfoRow(
                            title: "Data rozpoczęcia",
                            value: workout.startDate.formatted(date: .abbreviated, time: .shortened)
                        )
                        WorkoutInfoRow(
                            title: "Data zakończenia",
                            value: workout.endDate.formatted(date: .abbreviated, time: .shortened)
                        )
                        WorkoutInfoRow(
                            title: "Spalone kalorie",
                            value: (
                                workout.statistics(for: .init(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
                            ).map {
                                Measurement(value: $0, unit: UnitEnergy.kilocalories)
                                    .formatted(.measurement(width: .abbreviated, usage: .workout))
                            } ?? "--"
                        )
                        WorkoutInfoRow(
                            title: "Źródło",
                            value: workout.sourceRevision.source.name
                        )
                        WorkoutInfoRow(
                            title: "Urządzenie",
                            value: workout.device?.name ?? "--"
                        )
                        WorkoutInfoRow(
                            title: "Średnie tętno",
                            value: summary.metrics.averageHeartRate.formatted(.number.precision(.fractionLength(0)))
                        )
                        WorkoutInfoRow(
                            title: "Aktualne tętno",
                            value: summary.metrics.heartRate.formatted(.number.precision(.fractionLength(0)))
                        )
                        WorkoutInfoRow(
                            title: "Spalone kalorie na podstawie metryk",
                            value: Measurement(value: summary.metrics.activeEnergy, unit: UnitEnergy.kilocalories)
                                .formatted(.measurement(width: .abbreviated, usage: .workout))
                        )
                    } else {
                        Text("Brak danych")
                    }
                }
                .padding()
                
            }
            .scrollEdgeEffectStyle(.hard, for: .top)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        }
        doneButton
            .padding()
    }
    
    private var doneButton: some View {
        Button {
            send(.endWorkoutButtonTapped)
        } label: {
            Text("Gotowe")
                .bold()
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .foregroundStyle(.green)
        .tint(.green.opacity(0.2))
    }
    //    private var titleView: some View {
    //
    //    }
}

#Preview("loading") {
    SummaryView(store: Store(initialState: SummaryFeature.State(), reducer: {
        SummaryFeature()
    }))
}

#Preview("successfullyLoaded") {
    SummaryView(store: Store(initialState: SummaryFeature.State(viewState: .successfullyLoaded), reducer: {
        SummaryFeature()
    }))
}

struct WorkoutInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension TimeInterval {
    func formattedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .short
        return formatter.string(from: self) ?? "--"
    }
}
