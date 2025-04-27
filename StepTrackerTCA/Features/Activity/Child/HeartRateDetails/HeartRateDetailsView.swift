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
            heartRateWorkoutWidget
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
        } label: {
            chartHeaderView
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
    var heartRateWorkoutWidget: some View {
        VStack(alignment: .leading) {
            chartView
            Spacer().frame(height: 15)
            chartFooterView
        }
        .padding()
    }
    
    @ViewBuilder
    var chartHeaderView: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    Text("Heart Rate Range")
                    Spacer()
                    Text("\(store.hrData.first?.minute ?? .now, format: .dateTime.month().day().year())")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Label("\(store.lowestMinHR, format: .number) - \(store.highestMaxHR, format: .number) BMP", systemImage: "heart.fill")
                .foregroundColor(.pink)
        }
        .padding(.leading, 10)
        .padding(.bottom, -25)
    }
    
    @ViewBuilder
    var chartFooterView: some View {
        Text("\(Int(store.activeEnergyBurned), format: .number) KCLA")
    }
    
    @ViewBuilder
    private var chartView: some View {
        createChartView(store.hrData)
            .padding(.top, 4)
    }
    
}

//Text(Date.now, format: Date.FormatStyle(date: .numeric, time:.shortened))

//            Text("\(SalesData.salesInPeriod(in: scrollPositionStart...scrollPositionEnd), format: .number) PLN")


//Text("\(scrollPositionString) – \(scrollPositionEndString)")
