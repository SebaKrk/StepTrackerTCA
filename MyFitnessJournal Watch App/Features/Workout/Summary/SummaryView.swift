//
//  SummaryView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI
import HealthKit

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                totalTime
                totalEnergy
                avgHeartRate
                activityRingsView
            }
            doneButton
        }
    }
    
    private var totalTime: some View {
        SummaryMetricView(title: "Total Time",
                          value: "32:00:23", .yellow)
        
    }
    private var totalEnergy: some View {
        SummaryMetricView(title: "Total Energy",
                          value: Measurement(value: 632,
                                             unit: UnitEnergy.kilocalories)
                            .formatted(.measurement(width: .abbreviated,
                                                    usage: .workout,
                                                    numberFormatStyle: .number.precision(.fractionLength(0)))), .pink)
    }
    private var avgHeartRate: some View {
        SummaryMetricView(title: "Avg. Heart Rate",
                          value: 123.formatted(.number.precision(.fractionLength(0))) + " bpm", .red)
    }
    
    private var activityRingsView: some View {
        ActivityRingsView(healthStore: HKHealthStore())
    }
    
    private var doneButton: some View {
        Button("Done") {
            send(.doneButtonPressed)
        }
    }
    
}

#Preview {
    SummaryView(store: Store(initialState: SummaryFeature.State(), reducer: {
        SummaryFeature()
    }))
}
