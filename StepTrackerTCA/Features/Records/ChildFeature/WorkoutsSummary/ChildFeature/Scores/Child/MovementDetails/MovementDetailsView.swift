//
//  MovementDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import ComposableArchitecture
import SwiftUI
import Charts

@ViewAction(for: MovementDetailsFeature.self)
struct MovementDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MovementDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            chartGroupBox
                .frame(height: 350)
            options
            Spacer()
        }
        .padding()
        .navigationTitle("\(store.movement) details")
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.showMovementHistory,
                action: \.destination.showMovementHistory)) { store in
                    MovementHistoryView(store: store)
                }
    }
    
    private var chartGroupBox: some View {
        GroupBox {
            chartView
        } label: {
            headerTitle
        }
    }
    
    private var options: some View {
        List {
            Section {
                historyButton
            } header: {
                Text("Option")
            }
        }
        .listStyle(.plain)
    }
    
    private var historyButton: some View {
        Button {
            send(.tapHistoryButton)
        } label: {
            HStack {
                Text("Movement history")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
        if let filteredMovement = store.filteredMovement, !filteredMovement.movements.isEmpty {
            createChartView(filteredMovement)
        } else {
            ChartContentUnavailable()
        }
    }
    
    private var headerTitle: some View {
        ChartGroupBoxHeader(title: store.movement,
                            systemImage: store.movement,
                            color: .green, destination: false)
    }
    
    @ViewBuilder
    private func createChartView(_ movements: GroupedMovement) -> some View {
        Chart {
            if !store.goalIntervals.isEmpty {
                ForEach(store.goalIntervals, id: \.start) { interval in
                    createGoalRuleMarkIntervals(start: interval.start, end: interval.end, value: interval.value)
                }
            } else if let goal = movements.goals?.first?.value {
                createGoalRuleMark(goal)
            }
            
            if let selectedPoint = store.selectedPoint {
                selectedPointMark(with: selectedPoint) {
                    annotationView
                }
            }
            
            ForEach(movements.movements, id: \.id) { item in
                createPointMark(with: item)
            }
        }
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
    }
    
    private var annotationView: some View {
        ChartAnnotationView(
            date: store.selectedPoint?.date ?? .now,
            value: store.selectedPoint?.value ?? 0,
            color: .green
        )
    }
    
}
