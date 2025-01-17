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
            if store.stepData.isEmpty {
                ProgressView()
            } else {
                stepPieGroupBox
            }
        }
        .frame(height: 250)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    @ViewBuilder
    var stepPieGroupBox: some View {
        GroupBox {
            stepsPieChart
        } label: {
            groupBoxTitle("Averages",
                          "calendar",
                          "Last 28 Days",
                          destination: false)
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    var stepsPieChart: some View {
        Chart {
            ForEach(store.stepDataPerWeekDay) { weekday in
                SectorMark(angle: .value("Average Steps", weekday.value),
                           innerRadius: .ratio(0.618),
                           outerRadius: store.selectedChartValue?.date.weekdayInt == weekday.date.weekdayInt ? 140 : 110,
                           angularInset: 1)
                .foregroundStyle(.pink.gradient)
                .cornerRadius(6)
                .opacity(store.selectedChartValue?.date.weekdayInt == weekday.date.weekdayInt ? 1.0 : 0.3)
            }
        }
        .chartAngleSelection(value: $store.rawSelectedChartValue.animation(.easeInOut))
        .frame(height: 240)
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
    private func groupBoxTitle(_ title: String, _ systemImage: String, _ secondaryText: String, destination: Bool = true) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if destination {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    @ViewBuilder
    func pieTextView(_ title: String, _ value: Double) -> some View {
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
    
}

#Preview {
    NavigationStack {
        StepPieWidgetView(store: Store(initialState: StepPieWidgetFeature.State(stepData: MockData.steps), reducer: {
            StepPieWidgetFeature(service: DefaultStepPieWidget() )
        }))
    }
}
