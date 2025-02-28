//
//  ExerciseDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import SwiftUI
import Charts

@ViewAction(for: ExerciseDetailsFeature.self)
struct ExerciseDetailsView: View {
        
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ExerciseDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            chartGroupBox {
                chartView
            }
            .padding()
            .frame(height: 350)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private func chartGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            headerTitle
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    private var headerTitle: some View {
        ChartGroupBoxHeader(title: "Clean&Jerk",
                            systemImage: "figure.strengthtraining.traditional",
                            secondaryText: "Avg score 100 kg",
                            color: .green, destination: false)
    }
    
    private var chartView: some View {
        Chart {
            if let goal = store.goal {
                createGoalRuleMark(goal)
            }
            ForEach(store.chartData) { data in
                createAreaMark(with: data)
                createWeightLineMark(with: data)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel()
            }
        }
    }
    

    
}

