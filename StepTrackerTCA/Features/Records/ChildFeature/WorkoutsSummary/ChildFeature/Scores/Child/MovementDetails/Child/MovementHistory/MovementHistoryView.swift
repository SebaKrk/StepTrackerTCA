//
//  MovementHistoryView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/04/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: MovementHistoryFeature.self)
struct MovementHistoryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MovementHistoryFeature>
    
    // MARK: - View
    
    var body: some View {
        List {
            Section {
                ForEach(store.selectedMovement.movements) { item in
                    cell(item.date, item.value)
                }
            } header: {
                movementSectionTitle
            }
            if let goals = store.selectedMovement.goals, !goals.isEmpty {
                Section {
                    ForEach(goals) { goal in
                        cell(goal.date, goal.value)
                    }
                } header: {
                    goalSectionTitle
                }
            }
        }
        .navigationTitle("Movement history")
        .onAppear {
            send(.viewDidAppear)
        }

    }
    
    // MARK: - SubView
    
    private func cell(_ date: Date, _ value: Double) -> some View {
        HStack {
            Text(date.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Text("\(value, format: .number) kg")
        }
    }
    
    private var movementSectionTitle: some View {
        Text("\(store.selectedMovement.workoutType.rawValue) - \(store.selectedMovement.movements.first?.movement ?? "")")
    }
    
    private var goalSectionTitle: some View {
        Text("Goals")
    }
    
}

