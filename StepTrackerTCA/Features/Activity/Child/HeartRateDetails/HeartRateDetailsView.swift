//
//  HeartRateDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import ComposableArchitecture
import Charts
import SwiftUI
import HealthKit

@ViewAction(for: HeartRateDetailsFeature.self)
struct HeartRateDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HeartRateDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 5) {
            hrGroupBox
            hrDetails
        }
        .navigationTitle("Heart Rate Details")
        .onAppear {
            send(.viewDidAppear)
        }
    }

    private var hrGroupBox: some View {
        GroupBox {
            chartView
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
        }
        .padding([.leading, .trailing], 6)
        
    }
    
    private var hrDetails: some View {
        Form {
            DisclosureGroup("Details HR", isExpanded: $store.isExpandDetails) {
                ForEach(store.sample, id: \.startDate) { sample in
                    sampleCell(sample)
                }
            }
        }
    }
    
    private var detailsHeartRateList: some View {
        List {
            Section {
                ForEach(store.sample, id: \.startDate) { sample in
                    sampleCell(sample)
                }
            } header: {
                sectionHeaderTitle
            }
            
        }
    }
    
    private func sampleCell(_ sample: HKQuantitySample) -> some View {
        HStack {
            Text(sample.startDate, style: .time)
            Spacer()
            let bpm = sample.quantity.doubleValue(
                for: .count().unitDivided(by: .minute())
            )
            bmpCell(bpm)
        }
    }
    
    private func bmpCell(_ bpm: Double)  -> some View {
        Label("\(Int(bpm)) BMP", systemImage: "heart.fill")
    }
    
    private var sectionHeaderTitle: some View {
        Text("\(store.workoutType): \(store.startWorkout, format: Date.FormatStyle.dateTime.day().month(.twoDigits).year().hour().minute()) - \(store.endWorkout,format: Date.FormatStyle.dateTime.hour().minute())")
    }
    
    @ViewBuilder
    private var chartView: some View {
        createChartView(store.hrData)
    }
    
    @ViewBuilder
    private func createChartView(_ hrData: [HeartRateMetricsMinute]) -> some View {
        Chart {
            ForEach(hrData, id: \.minute) { stats in
                BarMark(
                    x: .value("Minute", stats.minute, unit: .minute),
                    yStart: .value("HR min", stats.minHR),
                    yEnd: .value("HR max", stats.maxHR)
                )
            }
            
        }
        
    }
    
}
