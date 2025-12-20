//
//  ActivitiesView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthKit

@ViewAction(for: ActivitiesFeature.self)
struct ActivitiesView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivitiesFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            switch store.viewState {
            case .loading:
                progressView
            case .success:
                rootView
            case .failed:
                Text("failed")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }

    }
        
    private var rootView: some View {
        VStack(spacing: 0) {
            trainingTabPicker
            switch store.context {
            case .personal:
                personalActivityView
            case .team:
                teamActivityView
            }
        }
        .background(LinearGradient(colors: [store.color.opacity(0.25
                                                               ), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        .padding([.leading, .trailing], 8)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.workouts.isEmpty {
                toolbarButton
            }
        }
        .id(store.workouts.count)
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Sort by") {
                    ForEach(ActivitiesSortOption.allCases) { item in
                        Button {
                            send(.changeSortOption(item))
                        } label: {
                            HStack {
                                Text(item.title)
                                if store.sortDescriptors == item {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("Date range") {
                    ForEach(ActivityDateRange.allCases) { range in
                        Button {
                            send(.changeDays(range.rawValue))
                        } label: {
                            HStack {
                                Text(range.title)
                                if store.days == range.rawValue {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .badge(store.workouts.count)
        }
    }
    
    private var trainingTabPicker: some View {
        Picker("trainingTabPicker", selection: $store.context.sending(\.selectedPickerChange)) {
            ForEach(ActivitiesFeature.TrainingTabContext.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing, .bottom], 6)
    }
    
    private var progressView: some View {
        ProgressView()
    }
    
    @ViewBuilder
    private var personalActivityView: some View {
        List {
            if store.workouts.isEmpty {
                emptyWorkoutsView
            } else {
                ForEach(store.workouts, id: \.uuid) { workout in
                    workoutCard(workout)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
//        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
    
    private var emptyWorkoutsView: some View {
        ContentUnavailableView(
            "No Workouts",
            systemImage: "figure.run",
            description: Text("No workouts found for the selected period. Make sure you have granted HealthKit access and recorded some workouts.")
        )
    }
    
    private var teamActivityView: some View {
        List {
//            Text("teamActivityView")
            ForEach(Array(store.workouts.enumerated()), id: \.element.uuid) { index, workout in
                Text("\(index): \(workout.workoutActivityType.name) (\(workout.workoutActivityType.rawValue)) - \(workout.endDate.formatted(date: .omitted, time: .shortened))")
            }
        }
    }
    
    private func workoutCard(_ workout: HKWorkout) -> some View {
        GroupBox {
            VStack(spacing: 12) {
                workoutStats(workout)
                Divider()
                primaryZoneSection(workout)
            }
        } label: {
            VStack {
                workoutHeaderButton(workout)
                Divider()
            }
        }
         .styledGroupBox()
         .padding(4)
    }
    
    private func workoutHeaderButton(_ workout: HKWorkout) -> some View {
        Button {
            send(.openDetails(workout))
        } label: {
            workoutHeader(workout)
        }
    }
    
    private func workoutHeader(_ workout: HKWorkout) -> some View {
        HStack {
            Image(systemName: workout.workoutActivityType.iconNameSimple)
                .resizable()
                .scaledToFit()
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.name)
                    .foregroundColor(.primary)
                    .font(.title2)
                    .bold()
                HStack {
                    Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    Text("-")
                    Text(workout.endDate, style: .time)
                    Spacer()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
    }
    
    private func workoutStats(_ workout: HKWorkout) -> some View {
        HStack(spacing: 0) {
            statColumn(
                title: "Duration",
                value: String(format: "%d min", Int(workout.duration) / 60)
            )
            statColumn(
                title: "Cal Burned",
                value: String(workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()).formatted(.number.precision(.fractionLength(1))) ?? "—" )
            )
            statColumn(
                title: "Avg HR",
                value: String(workout.statistics(for: HKQuantityType(.heartRate))?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())).formatted(.number.precision(.fractionLength(1))) ?? "—")
            )
            statColumn(
                title: "Max HR",
                value: String(workout.statistics(for: HKQuantityType(.heartRate))?.maximumQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())).formatted(.number.precision(.fractionLength(1))) ?? "—")
            )

        }
    }
    
    private func statColumn(title: String, value: String) -> some View {
        HStack {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .bold()
            }
            Divider()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func primaryZoneSection(_ workout: HKWorkout) -> some View {
        // TODO: Zone
        HStack {
            Text("Primary Zone:")
                .font(.caption)
            Text(HeartRateZone.fatBurning.rawValue)
                .font(.caption)
                .bold()
            Spacer()
            
            Text("Time in zone:")
                .font(.caption)
            Text("23 min 42 sec")
                .font(.caption)
                .bold()
        }
        .padding(4)
    }

}
