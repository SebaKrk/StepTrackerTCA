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
        ScrollView {
            chartGroupBox
                .padding()
                .frame(height: 350)
        }
        .navigationTitle("\(store.movement) details")
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    private var chartGroupBox: some View {
        GroupBox {
            chartView
        } label: {
            headerTitle
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
    
    private func createChartView(_ movements: GroupedMovement) -> some View {
        Chart {
            if !store.goalIntervals.isEmpty {
                ForEach(store.goalIntervals, id: \.start) { interval in
                    createGoalRuleMarkIntervals(start: interval.start, end: interval.end, value: interval.value)
                }
            }
            else if let goal = movements.goals?.first?.value {
                createGoalRuleMark(goal)
            }
            
            ForEach(movements.movements, id: \.id) { item in
                createPointMark(with: item)
            }
        }
    }
    
}
