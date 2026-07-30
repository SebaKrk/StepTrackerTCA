//
//  PlansView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PlansFeature.self)
struct PlansView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PlansFeature>

    // MARK: - Body (structure)

    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
            case .success:
                plansListView
            case .failed:
                failedView
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                importPlanButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                addPlanButton
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.addPlan, action: \.destination.addPlan)
        ) { addPlanStore in
            AddPlanView(store: addPlanStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.planDetail, action: \.destination.planDetail)
        ) { planDetailStore in
            NavigationStack {
                PlanDetailView(store: planDetailStore)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.session, action: \.destination.session)
        ) { sessionStore in
            SessionView(store: sessionStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.importPlan, action: \.destination.importPlan)
        ) { importStore in
            ImportPlanView(store: importStore)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - List (structure)

    @ViewBuilder
    private var plansListView: some View {
        if store.sessions.isEmpty {
            emptyPlansView
        } else {
            List {
                ForEach(store.sessions) { workout in
                    workoutCard(workout)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Workout Card (structure)

    private func workoutCard(_ workout: TrainingSession) -> some View {
        GroupBox {
            workoutSummary(workout)
        } label: {
            workoutCardLabel(workout)
        }
        .styledGroupBox()
        .padding(4)
    }

    private func workoutCardLabel(_ workout: TrainingSession) -> some View {
        VStack {
            workoutHeaderButton(workout)
            Divider()
        }
    }

    private func workoutHeaderButton(_ workout: TrainingSession) -> some View {
        Button {
            send(.workoutTapped(workout))
        } label: {
            workoutHeader(workout)
        }
    }

    private func workoutHeader(_ workout: TrainingSession) -> some View {
        HStack {
            activityIcon(workout)
            headerTitles(workout)
            Spacer()
            chevron
        }
    }

    private func headerTitles(_ workout: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            titleText(workout)
            dateText(workout)
        }
    }

    private func workoutSummary(_ workout: TrainingSession) -> some View {
        VStack(spacing: 12) {
            statsRow(workout)
            Divider()
            exercisesText(workout)
        }
        .padding(4)
    }

    private func statsRow(_ workout: TrainingSession) -> some View {
        HStack(spacing: 0) {
            statColumn(title: durationTitle, value: formatDuration(workout), alignment: .leading)
                .frame(maxWidth: 110)
            statColumn(title: locationTitle, value: workout.location.title)
                .frame(maxWidth: 90)
            statColumn(title: typeTitle, value: formatTypes(workout), isLast: true)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Implementation

    private var importPlanButton: some View {
        Button {
            send(.importPlanTapped)
        } label: {
            Image(systemName: "qrcode.viewfinder")
        }
    }

    private var addPlanButton: some View {
        Button {
            send(.addPlanTapped)
        } label: {
            Image(systemName: "plus")
        }
    }

    private func activityIcon(_ workout: TrainingSession) -> some View {
        Image(systemName: workout.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 40, height: 40)
    }

    private func titleText(_ workout: TrainingSession) -> some View {
        Text(workout.title)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dateText(_ workout: TrainingSession) -> some View {
        Text(workout.date, style: .date)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
    }

    private func exercisesText(_ workout: TrainingSession) -> some View {
        Text(exercisesLine(workout))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Reusable stat cell primitive — title over value with a trailing divider.
    private func statColumn(
        title: String,
        value: String,
        alignment: HorizontalAlignment = .center,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))

            if !isLast {
                Divider()
                    .frame(height: 36)
            }
        }
    }

    private let durationTitle = String(localized: "Duration")
    private let locationTitle = String(localized: "Location")
    private let typeTitle = String(localized: "Type")

    // MARK: - Helpers

    private func formatDuration(_ workout: TrainingSession) -> String {
        let total = (workout.warmUp?.time ?? 0)
            + workout.workouts.compactMap { $0.timeCap }.reduce(0, +)
            + (workout.coolDown?.time ?? 0)
        return total > 0 ? "~\(total) min" : "–"
    }

    private func formatTypes(_ workout: TrainingSession) -> String {
        let types = Array(Set(workout.workouts.map { $0.type.displayName }))
        return types.isEmpty ? "–" : types.joined(separator: " · ")
    }

    private func exercisesLine(_ workout: TrainingSession) -> String {
        var seen = Set<String>()
        let names = workout.workouts
            .flatMap { $0.exercises }
            .map { $0.displayName }
            .filter { seen.insert($0).inserted }
        return names.isEmpty ? "–" : names.joined(separator: " · ")
    }

    // MARK: - Empty / Failed

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    private var emptyPlansView: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: "doc.text")
        } description: {
            Text(emptyMessage)
        } actions: {
            emptyAddButton
        }
    }

    private var emptyAddButton: some View {
        Button {
            send(.addPlanTapped)
        } label: {
            Label(addPlanTitle, systemImage: "plus")
        }
    }

    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load workout plans. Please try again.")
    private let emptyTitle = String(localized: "No Workout Plans")
    private let emptyMessage = String(localized: "Create workout plans by scanning your training notes or add them manually. Compare your plans with actual HealthKit results.")
    private let addPlanTitle = String(localized: "Add Plan")
}
