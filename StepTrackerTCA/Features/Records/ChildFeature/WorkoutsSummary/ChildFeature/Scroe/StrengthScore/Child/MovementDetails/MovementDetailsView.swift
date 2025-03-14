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
        if let data = store.data {
            createChartView(data)
        } else {
            ChartContentUnavailable()
        }
    }
    
    private var headerTitle: some View {
        ChartGroupBoxHeader(title: store.movement.title,
                            systemImage: "dumbbell.fill",
                            color: .green, destination: false)
    }
    
    private func createChartView(_ data: [WorkoutStrength]) -> some View {
        Chart {
            /// Jeśli pierwszy obiekt ma wartość, spróbuj przekonwertować na Double
            if let goal = data.first?.value {
                createGoalRuleMark(goal)
            }
            ForEach(data) { data in
                createPointMark(with: data)
            }
        }
    }

    
}
