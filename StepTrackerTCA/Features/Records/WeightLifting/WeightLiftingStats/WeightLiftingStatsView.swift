//
//  WeightLiftingStatsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightLiftingStatsFeature.self)
struct WeightLiftingStatsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightLiftingStatsFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            weightLiftingGoalsBody
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    WeightLiftingGoalsView(store: store)
                }
    }
    
    // MARK: - SubView
    
    private var weightLiftingGoalsBody: some View {
        weightLiftingGoalsWidget
    }
    
    private var weightLiftingGoalsWidget: some View {
        GroupBox {
            weightLiftingGoalsContent
        } label: {
            weightLiftingGoalsTitleHeader
        }
        .frame(minHeight: 200)
    }
    
    private var weightLiftingGoalsTitleHeader: some View {
        WidgetHeaderView(title: "WeightLifting", systemImage: "figure.strengthtraining.traditional", color: .green) {
            send(.navigationButtonTapped)
        }
    }
    
    private var weightLiftingGoalsContent: some View {
        VStack {
            WidgetBodyContentWithButton(title: "Score:",
                              color: .green) {
                // Jeśli nie będzie ustawionego żadnego gola to pokaz:
                // AnyView(setYourGoalsButton)
                // jesli sa gole ale no nie ma wyniku to chyba cos w rodzaju Content uvaiable
                // w innym przypadku pokazuj
                AnyView(
                    VStack {
                        weightLiftingScore("Back Squat", "140")
                        Divider().padding(.horizontal, 20)
                        weightLiftingScore("Front Squat", "110")
                        Divider().padding(.horizontal, 20)
                        weightLiftingScore("Deadlift", "160")
                        Divider().padding(.horizontal, 20)
                        weightLiftingScore("Push Press", "90")
                        Divider().padding(.horizontal, 20)
                        weightLiftingScore("Bench Press", "120")
                    }
                )
            }
            Spacer()
        }
    }
    
    // a moze dac Tabele ?
    // gdzie bedzie pokazane nazwa / wynik / gol / procent ile brakuje
    func missingPercentage(current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        let missing = ((goal - current) / goal) * 100
        return missing
    }
    
    private var setYourGoalsButton: some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Text("Set your goals")
                .foregroundStyle(.red)
        }
    }
    
    private func weightLiftingScore(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
            Spacer()
            Text("\(value) kg")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        }
    }
}

#Preview {
    WeightLiftingStatsView(store: Store(initialState: WeightLiftingStatsFeature.State(), reducer: {
        WeightLiftingStatsFeature(service: DefaultWeightLiftingStatsServices())
    }))
}
