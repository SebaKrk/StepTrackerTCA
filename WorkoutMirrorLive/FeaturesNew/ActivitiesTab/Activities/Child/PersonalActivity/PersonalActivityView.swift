//
//  PersonalActivityView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthKit

@ViewAction(for: PersonalActivityFeature.self)
struct PersonalActivityView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<PersonalActivityFeature>
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success:
                workoutsListView
            case .failed:
                failedView
            }
        }
        .animation(.default, value: store.viewState)
        .toolbar {
            if !store.workouts.isEmpty {
                toolbarButton
            }
        }
        .sheet(
            item: $store.scope(state: \.destination?.zoneInfo, action: \.destination.zoneInfo)
        ) { zoneInfoStore in
            // NavigationStack provides the title bar — HeartRateZoneInfoView no
            // longer carries its own NavigationView (see that file's comment).
            NavigationStack {
                HeartRateZoneInfoView(store: zoneInfoStore)
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.activityDetails,
                action: \.destination.activityDetails
            )
        ) { detailsStore in
            ActivityDetailsView(store: detailsStore)
        }
        .alert(store: store.scope(state: \.$deleteAlert, action: \.alert))
        .alert(store: store.scope(state: \.$errorAlert, action: \.errorAlert))
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Toolbar
    
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
    
    // MARK: - List View
    
    @ViewBuilder
    private var workoutsListView: some View {
        if store.workouts.isEmpty {
            emptyWorkoutsView
        } else {
            List {
                ForEach(store.workouts, id: \.uuid) { workout in
                    workoutCard(workout)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                send(.deleteWorkoutSwiped(workout))
                            } label: {
                                Label("Usuń", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                send(.refresh)
            }
        }
    }
    
    // MARK: - Workout Card
    
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
                    if store.pendingResultWorkoutIds.contains(workout.uuid) {
                        pendingResultsBadge
                    }
                    Spacer()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
    }

    /// Plan auto-linked (IOS-00098-C) but results not entered yet — nudges the user
    /// into the manual-entry flow in ActivityDetails (IOS-00098-F).
    /// Sits inline in the date row (user decision 2026-07-04) — compact paddings
    /// so the chip does not stretch the row height.
    private var pendingResultsBadge: some View {
        Text(String(localized: "Uzupełnij wyniki"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(.orange.opacity(0.15), in: Capsule())
    }

    /// Frozen effort points (Myzone-style) — inline at the end of the primary-zone
    /// row (next to the info button), since the points are earned from time in
    /// zones. Shown only when a score is stored (observed via `effortScores`).
    private func effortPointsInline(_ points: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
            Text("\(points)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.caption)
        .foregroundStyle(.yellow)
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
    
    // MARK: - Primary zone row (structure)

    private func primaryZoneSection(_ workout: HKWorkout) -> some View {
        HStack(spacing: 6) {
            primaryZoneLabel
            primaryZoneValue(workout)
            Spacer(minLength: 8)
            timeInZoneLabel
            timeInZoneValue(workout)
            effortPointsBadge(workout)
        }
        .padding(4)
    }

    // MARK: - Primary zone row (implementation)

    private var primaryZoneLabel: some View {
        Text("Primary Zone:")
            .font(.caption)
    }

    @ViewBuilder
    private func primaryZoneValue(_ workout: HKWorkout) -> some View {
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
    }

    private var timeInZoneLabel: some View {
        Text("Time in zone:")
            .font(.caption)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func timeInZoneValue(_ workout: HKWorkout) -> some View {
        if let zoneInfo = store.zoneInfo[workout.uuid] {
            Text(formatDuration(zoneInfo.duration))
                .font(.caption)
                .bold()
                // Keep the duration on one line — the flexible Spacer yields space
                // instead of the value wrapping to two rows.
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
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

    /// Frozen effort points for the workout — hidden when no score is stored.
    @ViewBuilder
    private func effortPointsBadge(_ workout: HKWorkout) -> some View {
        if let points = store.effortPointsByWorkout[workout.uuid] {
            effortPointsInline(points)
        }
    }
    
    // MARK: - Helpers
    
    /// Compact "25m 21s" (adds "Xh" past an hour) — the primary-zone row is tight
    /// once the points badge is present, so the value stays terse and on one line.
    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }

    // MARK: - Empty/Failed Views
    
    private var failedView: some View {
        ContentUnavailableView {
            Label("HealthKit Access Required", systemImage: "heart.text.square")
        } description: {
            Text("To see your workouts, please grant access to HealthKit in Settings.")
        } actions: {
            Button {
                // TODO: - Open Health Settings
            } label: {
                Label("Open Settings", systemImage: "gear")
            }
        }
    }
    
    private var emptyWorkoutsView: some View {
        ContentUnavailableView {
            Label("No Workouts", systemImage: "figure.run")
        } description: {
            Text("No workouts found for the selected period. Make sure you have granted HealthKit access and recorded some workouts.")
        }
    }
    
}
