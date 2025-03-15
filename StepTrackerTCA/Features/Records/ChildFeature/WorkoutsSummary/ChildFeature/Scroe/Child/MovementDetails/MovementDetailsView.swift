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
        .navigationTitle("\(store.movement.title) details")
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
        if store.sessions.isEmpty {
            ChartContentUnavailable()
        } else {
            createChartView(store.sessions)
        }
    }
    
    private var headerTitle: some View {
        ChartGroupBoxHeader(title: store.movement.title,
                            systemImage: store.movement.icon,
                            color: .green, destination: false)
    }
    
    private func createChartView(_ sessions: [any WorkoutSessionProtocol]) -> some View {
        Chart {
            /// Jeśli pierwszy obiekt ma wartość, spróbuj przekonwertować na Double
            if let goal = sessions.first?.value {
                createGoalRuleMark(goal)
            }
            ForEach(sessions, id: \.id) { data in
                createPointMark(with: data)
            }
        }
    }
}
