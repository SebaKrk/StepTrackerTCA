//
//  ExerciseAnalyticsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ExerciseAnalyticsFeature.self)
struct ExerciseAnalyticsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ExerciseAnalyticsFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthSelector
                movementBalanceCard
                sortModePicker
                exerciseListCard
            }
            .padding()
        }
        .onAppear {
            send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { store in
            NavigationStack {
                ExerciseDetailView(store: store)
            }
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            previousMonthButton
            Spacer()
            monthTitleText
            Spacer()
            nextMonthButton
        }
        .padding(.horizontal)
    }

    private var monthTitleText: some View {
        Text(store.selectedMonth, format: .dateTime.month(.wide).year())
            .font(.headline)
    }

    private var previousMonthButton: some View {
        let isDisabled = store.exerciseLogs.isEmpty && !isCurrentMonth
        return monthChangeButton(
            icon: "chevron.left",
            isDisabled: isDisabled
        ) {
            let newDate = Calendar.current.date(byAdding: .month, value: -1, to: store.selectedMonth) ?? store.selectedMonth
            send(.monthChanged(newDate))
        }
    }

    private var nextMonthButton: some View {
        monthChangeButton(
            icon: "chevron.right",
            isDisabled: isCurrentMonth
        ) {
            let newDate = Calendar.current.date(byAdding: .month, value: 1, to: store.selectedMonth) ?? store.selectedMonth
            send(.monthChanged(newDate))
        }
    }

    private func monthChangeButton(
        icon: String,
        isDisabled: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            onTap()
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(store.selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Movement Balance Card

    private var movementBalanceCard: some View {
        GroupBox {
            movementBalanceContent
        } label: {
            movementBalanceHeader
        }
        .styledGroupBox()
    }

    private var movementBalanceHeader: some View {
        VStack {
            HStack {
                Text(String(localized: "Movement Balance"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }
            Divider()
        }
    }

    // MARK: - Sort Mode Picker

    private var sortModePicker: some View {
        Picker(
            String(localized: "Sort by"),
            selection: Binding<ExerciseAnalyticsSortMode>(
                get: { store.sortMode },
                set: { send(.sortModeChanged($0)) }
            )
        ) {
            Text(String(localized: "Frequency"))
                .tag(ExerciseAnalyticsSortMode.frequency)
            Text(String(localized: "Weight"))
                .tag(ExerciseAnalyticsSortMode.weight)
            Text(String(localized: "Volume"))
                .tag(ExerciseAnalyticsSortMode.volume)
        }
        .pickerStyle(.segmented)
    }

    private var sortModeDescriptionText: String {
        switch store.sortMode {
        case .frequency:
            return String(localized: "How often each exercise appeared in your training")
        case .weight:
            return String(localized: "Peak load recorded per exercise")
        case .volume:
            return String(localized: "Total load moved — reps × weight")
        }
    }

    // MARK: - Exercise List Card

    private var exerciseListCard: some View {
        GroupBox {
            exerciseListContent
        } label: {
            exerciseListHeader
        }
        .styledGroupBox()
    }

    private var exerciseListHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(String(localized: "Exercises"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }
            Text(sortModeDescriptionText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Divider()
        }
    }

    @ViewBuilder
    private var exerciseListContent: some View {
        if store.exerciseSummaries.isEmpty {
            exerciseListEmpty
        } else {
            VStack(spacing: 0) {
                ForEach(store.exerciseSummaries) { summary in
                    exerciseRow(summary)
                    if summary.id != store.exerciseSummaries.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var exerciseListEmpty: some View {
        ChartContentUnavailable(
            systemImage: "list.bullet.clipboard",
            description: String(localized: "No exercises logged this month.")
        )
        // Matches movementBalanceEmpty — see the note there.
        .frame(height: 200)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ summary: ExerciseSummary) -> some View {
        Button {
            send(.exerciseTapped(summary.exerciseType))
        } label: {
            HStack(spacing: 12) {
                exerciseRowDot(summary)
                exerciseRowHeader(summary)
                Spacer()
                exerciseRowTrailing(summary)
                exerciseRowChevron
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func exerciseRowDot(_ summary: ExerciseSummary) -> some View {
        Circle()
            .fill(summary.category.color)
            .frame(width: 8, height: 8)
    }

    private func exerciseRowHeader(_ summary: ExerciseSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(summary.exerciseType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if summary.hasPR {
                    prBadge
                }
            }
            Text(summary.category.displayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func exerciseRowTrailing(_ summary: ExerciseSummary) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(summary.count)\u{00D7}")
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
            if store.sortMode != .frequency {
                exerciseWeightLabel(summary)
            }
        }
    }

    private var exerciseRowChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private var prBadge: some View {
        Text("PR")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.orange, in: RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private func exerciseWeightLabel(_ summary: ExerciseSummary) -> some View {
        if let maxWeight = summary.maxWeight, maxWeight > 0 {
            Text("\(maxWeight, specifier: "%.1f") kg")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Text(String(localized: "BW"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseAnalyticsView(
        store: Store(
            initialState: ExerciseAnalyticsFeature.State(
                exerciseLogs: [
                    ExerciseLog(
                        exerciseType: .backSquat,
                        category: .strength,
                        actualWeight: 120,
                        isPR: true,
                        volumeLoad: 3600
                    ),
                    ExerciseLog(
                        exerciseType: .backSquat,
                        category: .strength,
                        actualWeight: 110,
                        volumeLoad: 3300
                    ),
                    ExerciseLog(
                        exerciseType: .snatch,
                        category: .olympicLifting,
                        actualWeight: 70,
                        volumeLoad: 2100
                    ),
                    ExerciseLog(
                        exerciseType: .pullUps,
                        category: .gymnastics,
                        isPR: false,
                        volumeLoad: 0
                    ),
                    ExerciseLog(
                        exerciseType: .pullUps,
                        category: .gymnastics,
                        volumeLoad: 0
                    ),
                    ExerciseLog(
                        exerciseType: .pullUps,
                        category: .gymnastics,
                        volumeLoad: 0
                    ),
                    ExerciseLog(
                        exerciseType: .running,
                        category: .cardio,
                        volumeLoad: 0
                    ),
                    ExerciseLog(
                        exerciseType: .burpees,
                        category: .mixed,
                        volumeLoad: 0
                    ),
                ]
            )
        ) {
            ExerciseAnalyticsFeature()
        }
    )
}

#Preview("rich data") {
    var state = ExerciseAnalyticsFeature.State()
    state.selectedMonth = Date()
    state.exerciseLogs = {
        var logs: [ExerciseLog] = []
        let calendar = Calendar.current
        let now = Date()

        // Week 1
        let w1 = calendar.date(byAdding: .day, value: -21, to: now)!
        logs.append(ExerciseLog(date: w1, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 40, actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 165, volumeLoad: 1800))
        logs.append(ExerciseLog(date: w1, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 165))
        logs.append(ExerciseLog(date: w1, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 2", actualReps: "50", scaling: .rx, isPR: false, avgHeartRate: 170))

        // Week 2
        let w2 = calendar.date(byAdding: .day, value: -14, to: now)!
        logs.append(ExerciseLog(date: w2, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 43, actualReps: "15-12-9", scaling: .rx, isPR: false, avgHeartRate: 162, volumeLoad: 1548))
        logs.append(ExerciseLog(date: w2, exerciseType: .deadlift, category: .strength, wodName: "Strength", actualWeight: 100, actualReps: "5-5-5-5-5", scaling: .rx, isPR: false, avgHeartRate: 155, volumeLoad: 2500))
        logs.append(ExerciseLog(date: w2, exerciseType: .rowing, category: .cardio, wodName: "WOD 2", actualReps: "2000m", scaling: .rx, isPR: false, avgHeartRate: 172))
        logs.append(ExerciseLog(date: w2, exerciseType: .boxJumps, category: .mixed, wodName: "WOD 2", actualReps: "30", scaling: .rx, isPR: false, avgHeartRate: 168))

        // Week 3
        let w3 = calendar.date(byAdding: .day, value: -7, to: now)!
        logs.append(ExerciseLog(date: w3, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 43, actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 158, volumeLoad: 1935))
        logs.append(ExerciseLog(date: w3, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 1", actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 170))
        logs.append(ExerciseLog(date: w3, exerciseType: .wallBalls, category: .mixed, wodName: "WOD 2", actualWeight: 9, actualReps: "150", scaling: .rx, isPR: true, avgHeartRate: 175, volumeLoad: 1350))
        logs.append(ExerciseLog(date: w3, exerciseType: .handstandPushUps, category: .gymnastics, wodName: "WOD 2", actualReps: "30", scaling: .scaled, isPR: false, avgHeartRate: 160))

        // Week 4 (this week)
        let w4 = calendar.date(byAdding: .day, value: -1, to: now)!
        logs.append(ExerciseLog(date: w4, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 45, actualReps: "21-15-9", scaling: .rx, isPR: true, avgHeartRate: 170, volumeLoad: 2025))
        logs.append(ExerciseLog(date: w4, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 168))
        logs.append(ExerciseLog(date: w4, exerciseType: .cleanAndJerk, category: .olympicLifting, wodName: "Strength", actualWeight: 70, actualReps: "1-1-1", scaling: .rx, isPR: true, avgHeartRate: 150, volumeLoad: 210))
        logs.append(ExerciseLog(date: w4, exerciseType: .doubleUnders, category: .mixed, wodName: "WOD 2", actualReps: "200", scaling: .rx, isPR: false, avgHeartRate: 155))
        logs.append(ExerciseLog(date: w4, exerciseType: .rowing, category: .cardio, wodName: "WOD 2", actualReps: "1000m", scaling: .rx, isPR: false, avgHeartRate: 175))

        return logs
    }()
    return ExerciseAnalyticsView(
        store: Store(initialState: state) {
            ExerciseAnalyticsFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByDateRange = { _, _ in state.exerciseLogs }
        }
    )
}
