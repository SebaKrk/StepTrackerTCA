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
                failedView
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
        .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        .padding([.leading, .trailing], 8)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.workouts.isEmpty && store.context == .personal {
                toolbarButton
            }
        }
        .sheet(
            item: $store.scope(state: \.destination?.zoneInfo, action: \.destination.zoneInfo)
        ) { zoneInfoStore in
            HeartRateZoneInfoView(store: zoneInfoStore)
                .presentationDetents([.medium, .large])
        }
        .id(store.workouts.count)
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.activityDetails,
                action: \.destination.activityDetails)) { store in
                    ActivityDetailsView(store: store)
                }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Sort by") {
                    activitiesSortOption
                }
                Section("Date range") {
                    activityDateRange
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .badge(store.workouts.count)
        }
    }
    
    private var activitiesSortOption: some View {
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
    
    private var activityDateRange: some View {
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
        .listStyle(.plain)
    }
    
    // MARK: - SubView
    
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
                title: String(localized: "Duration", bundle: .main),
                value: String(format: "%d min", Int(workout.duration) / 60)
            )
            statColumn(
                title: String(localized: "Cal Burned", bundle: .main),
                value: String(workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()).formatted(.number.precision(.fractionLength(1))) ?? "–" )
            )
            statColumn(
                title: String(localized: "Avg HR", bundle: .main),
                value: String(workout.statistics(for: HKQuantityType(.heartRate))?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())).formatted(.number.precision(.fractionLength(1))) ?? "–")
            )
            statColumn(
                title: String(localized: "Max HR", bundle: .main),
                value: String(workout.statistics(for: HKQuantityType(.heartRate))?.maximumQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())).formatted(.number.precision(.fractionLength(1))) ?? "–")
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
        HStack {
            Text("Primary Zone:")
                .font(.caption)
            
            if let zoneInfo = store.zoneInfo[workout.uuid] {
                Text(zoneInfo.zone.title)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(zoneInfo.zone.color)
            } else {
                Text("–")
                    .font(.caption)
                    .bold()
            }
            
            Spacer()
            
            Text("Time in zone:")
                .font(.caption)
            
            if let zoneInfo = store.zoneInfo[workout.uuid] {
                Text(formatDuration(zoneInfo.duration))
                    .font(.caption)
                    .bold()
                Button {
                    send(.showZoneInfo(zoneInfo.zone))
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                }
            } else {
                Text("–")
                    .font(.caption)
                    .bold()
            }
            
        }
        .padding(4)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes) min \(seconds) sec"
    }
    
    private var progressView: some View {
        ProgressView()
    }
    
    private var failedView: some View {
        ContentUnavailableView {
            Label("HealthKit Access Required", systemImage: "heart.text.square")
        } description: {
            Text("To see your workouts, please grant access to HealthKit in Settings.")
        } actions: {
            Button {
                // TODO: - ...
                //send(.openHealthSettings)
            } label: {
                Label("Open Settings", systemImage: "gear")
            }
        }
    }
    
    private var emptyWorkoutsView: some View {
        ContentUnavailableView(
            "No Workouts",
            systemImage: "figure.run",
            description: Text("No workouts found for the selected period. Make sure you have granted HealthKit access and recorded some workouts.")
        )
    }
    
    private var teamActivityView: some View {
        emptyTeamActivityView
    }
    
    private var emptyTeamActivityView: some View {
        ContentUnavailableView {
            Label("No Team Yet", systemImage: "person.3")
        } description: {
            Text("Join a fitness group to track progress with your teammates and stay motivated together.")
        } actions: {
            Button {
                // TODO: - ...
            } label: {
                Label("Find a Club", systemImage: "magnifyingglass")
            }
        }
    }
    
}
