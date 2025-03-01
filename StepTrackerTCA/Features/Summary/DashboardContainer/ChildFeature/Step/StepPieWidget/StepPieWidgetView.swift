//
//  StepPieWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Charts
import SwiftUI

@ViewAction(for: StepPieWidgetFeature.self)
struct StepPieWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StepPieWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            if !store.stepData.isEmpty {
                stepPieGroupBox { stepsPieChart }
            } else {
                stepPieGroupBox { contentUnavailable }
            }
        }
        .frame(height: 300)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    private func stepPieGroupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            headerTitle
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var stepsPieChart: some View {
        Chart {
            ForEach(store.stepDataPerWeekDay) { weekday in
                createPieChart(for: weekday)
            }
        }
        .chartAngleSelection(value: $store.rawSelectedChartValue.animation(.easeInOut))
        .chartBackground { proxy in
            GeometryReader { geo in
                if let plotFrame = proxy.plotFrame {
                    let frame = geo[plotFrame]
                    Group {
                        if let selectedWeekday = store.selectedChartValue {
                            pieTextView(selectedWeekday.date.weekdayTitle,
                                        selectedWeekday.value)
                        } else {
                            pieTextView("Total Steps", store.totalStepsFrom28Days)
                        }
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }
    
    @ViewBuilder
    private func pieTextView(_ title: String, _ value: Double) -> some View {
        VStack {
            Text(title)
                .font(.title3.bold())
                .contentTransition(.identity)
            
            Text(value, format: .number.precision(.fractionLength(0)))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder
    private var headerTitle: some View {
        ChartGroupBoxHeader(
            title: "Averages",
            systemImage: "calendar",
            secondaryText: "Last 28 Days",
            color: .pink
        )
    }
    
    @ViewBuilder
    private var contentUnavailable: some View {
        ChartContentUnavailable()
    }
    
}

#Preview {
    NavigationStack {
        StepPieWidgetView(store: Store(initialState: StepPieWidgetFeature.State(stepData: MockData.steps), reducer: {
            StepPieWidgetFeature(service: DefaultStepPieWidget() )
        }))
    }
}
