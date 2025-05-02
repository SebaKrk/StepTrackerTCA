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
            Form {
                heartRateByMinuteList
                hrDetails
            }
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
    
    
    private var heartRateByMinuteList: some View {
        DisclosureGroup("Details HR by minute", isExpanded: $store.isExpandDetailsByMinute) {
            ForEach(store.hrData, id: \.minute) { data in
                sampleCellButton(data)
            }
        }
    }
    
    private func sampleCellButton(_ data: HeartRateMetricsMinute) -> some View {
        Button {
            send(.tapHRMetrics(data))
        } label: {
            hrDataCell(data)
        }
    }
    
    private func hrDataCell(_ data: HeartRateMetricsMinute) -> some View {
        HStack {
            Text("\(data.minute, style: .time)")
            Spacer()
            Text("\(data.minHR, format: .number) -")
            Text("\(data.maxHR, format: .number)")
            Text("BMP")
                .font(.caption2)
        }
    }
    
    private var hrDetails: some View {
        DisclosureGroup("Details HR", isExpanded: $store.isExpandDetails) {
            ForEach(store.sample, id: \.startDate) { sample in
                sampleCell(sample)
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
                .padding()
            Spacer().frame(height: 15)
            chartFooterView
        }
        
    }
    
    @ViewBuilder
    private var chartView: some View {
        createChartView(store.hrData)
            .padding(.top, 4)
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
        VStack(alignment: .leading, spacing: 4) {
            Label("\(Int(store.activeEnergyBurned), format: .number) kcal", systemImage: "flame.fill")
                .foregroundStyle(.pink)
            
            Text("Duration: \(store.workoutDurationInMinutes, format: .number.precision(.fractionLength(0))) min")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            
        }
    }
    
    @ViewBuilder
    func createChartView(_ hrData: [HeartRateMetricsMinute]) -> some View {
        Chart {
            if let selectedDate = store.rawSelectedDate {
                createRuleMark(with: selectedDate) { annotationView }
            }
            ForEach(hrData, id: \.minute) { stats in
                createBarMark(stats)
            }
            .foregroundStyle(.pink.opacity(0.9))
            .cornerRadius(4)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { value in
                AxisValueLabel()
            }
        }
    }
    
    @ViewBuilder
    private var annotationView: some View {
        ChartHRAnnotationView(
            date: store.selectedHeartRateMetric?.minute ?? .now,
            valueOne: store.selectedHeartRateMetric?.minHR ?? 0,
            valueTwo: store.selectedHeartRateMetric?.maxHR ?? 0,
            color: .pink
        )
    }
    
}

//Text(Date.now, format: Date.FormatStyle(date: .numeric, time:.shortened))

//            Text("\(SalesData.salesInPeriod(in: scrollPositionStart...scrollPositionEnd), format: .number) PLN")


//Text("\(scrollPositionString) – \(scrollPositionEndString)")



//    private var detailsHeartRateList: some View {
//        List(selection: $store.rawSelectedDate.sending(\.selectedChartMinChange)) {
////        List {
//            Section {
//                ForEach(store.sample, id: \.startDate) { sample in
//                    sampleCell(sample)
//                        .tag(sample.startDate)
//                }
//            } header: {
//                sectionHeaderTitle
//            }
//        }
//    }
