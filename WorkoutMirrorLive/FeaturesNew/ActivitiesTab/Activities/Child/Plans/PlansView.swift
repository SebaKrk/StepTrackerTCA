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
    
    // MARK: - Body
    
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
                Button {
                    send(.addPlanTapped)
                } label: {
                    Image(systemName: "plus")
                }
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
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - List View

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

    // MARK: - Workout Card

    private func workoutCard(_ workout: TrainingSession) -> some View {
        GroupBox {
            VStack(spacing: 12) {
                workoutSummary(workout)
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

    private func workoutHeaderButton(_ workout: TrainingSession) -> some View {
        Button {
            send(.workoutTapped(workout))
        } label: {
            workoutHeader(workout)
        }
    }

    private func workoutHeader(_ workout: TrainingSession) -> some View {
        HStack {
            Image(systemName: workout.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
                .resizable()
                .scaledToFit()
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .foregroundColor(.primary)
                    .font(.title2)
                    .bold()

                Text(workout.date, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
        }
    }

    private func workoutSummary(_ workout: TrainingSession) -> some View {
        VStack(spacing: 12) {
            // Kolumny stat (jak PersonalActivityView)
            HStack(spacing: 0) {
                statColumn(title: "Duration", value: formatDuration(workout), alignment: .leading)
                    .frame(maxWidth: 110)
                statColumn(title: "Location", value: workout.location.title)
                    .frame(maxWidth: 90)
                statColumn(title: "Type", value: formatTypes(workout), isLast: true)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            // Ćwiczenia — max 2 linie, szara czcionka, wyśrodkowane
            Text(exercisesLine(workout))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(4)
    }

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

    // MARK: - Empty/Failed Views

    private var failedView: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Unable to load workout plans. Please try again.")
        }
    }
    
    private var emptyPlansView: some View {
        ContentUnavailableView {
            Label("No Workout Plans", systemImage: "doc.text")
        } description: {
            Text("Create workout plans by scanning your training notes or add them manually. Compare your plans with actual HealthKit results.")
        } actions: {
            Button {
                send(.addPlanTapped)
            } label: {
                Label("Add Plan", systemImage: "plus")
            }
        }
    }
    
}
