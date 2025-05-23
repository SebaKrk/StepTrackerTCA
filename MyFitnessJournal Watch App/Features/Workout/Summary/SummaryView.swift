//
//  SummaryView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SummaryMetricView(title: "Total Time",
                                  value: "32:00:23")
                .foregroundStyle(.yellow)
 
                SummaryMetricView(title: "Total Energy",
                                  value: Measurement(value: 632,
                                                     unit: UnitEnergy.kilocalories)
                                    .formatted(.measurement(width: .abbreviated,
                                                            usage: .workout,
                                                            numberFormatStyle: .number.precision(.fractionLength(0)))))
                .foregroundStyle(.pink)
                SummaryMetricView(title: "Avg. Heart Rate",
                                  value: 123.formatted(.number.precision(.fractionLength(0))) + " bpm")
                .foregroundStyle(.red)
            }
            
            doneButton
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            send(.doneButtonPressed)
        }
    }
    
}
