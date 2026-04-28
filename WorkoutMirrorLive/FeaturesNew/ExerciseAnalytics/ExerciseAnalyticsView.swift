//
//  ExerciseAnalyticsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import Charts
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
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            previousMonthButton
            Spacer()
            Text(store.selectedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            nextMonthButton
        }
        .padding(.horizontal)
    }

    private var previousMonthButton: some View {
        Button {
            let newDate = Calendar.current.date(byAdding: .month, value: -1, to: store.selectedMonth) ?? store.selectedMonth
            send(.monthChanged(newDate))
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    private var nextMonthButton: some View {
        Button {
            let newDate = Calendar.current.date(byAdding: .month, value: 1, to: store.selectedMonth) ?? store.selectedMonth
            send(.monthChanged(newDate))
        } label: {
            Image(systemName: "chevron.right")
                .font(.title3)
                .fontWeight(.semibold)
        }
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
                Text(String(localized: "Movement Balance", bundle: .main))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }
            Divider()
        }
    }

    private var movementBalanceContent: some View {
        VStack(spacing: 12) {
            if store.exerciseLogs.isEmpty {
                ChartContentUnavailable(
                    systemImage: "figure.mixed.cardio",
                    description: String(localized: "No exercise data for this month.", bundle: .main)
                )
                .frame(height: 200)
            } else {
                movementBalanceChart
                Divider()
                categoryLegend
            }
        }
    }

    private var movementBalanceChart: some View {
        Chart {
            ForEach(Array(store.weeklyBreakdown.enumerated()), id: \.offset) { weekIndex, breakdown in
                ForEach(MovementCategory.allCases, id: \.self) { category in
                    if let count = breakdown[category], count > 0 {
                        BarMark(
                            x: .value(
                                String(localized: "Week", bundle: .main),
                                "W\(weekIndex + 1)"
                            ),
                            y: .value(
                                String(localized: "Count", bundle: .main),
                                count
                            )
                        )
                        .foregroundStyle(category.color)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 200)
    }

    private var categoryLegend: some View {
        let totalCount = store.categoryBreakdown.values.reduce(0, +)

        return VStack(spacing: 6) {
            ForEach(MovementCategory.allCases, id: \.self) { category in
                if let count = store.categoryBreakdown[category], count > 0 {
                    categoryLegendRow(category: category, count: count, total: totalCount)
                }
            }
        }
    }

    private func categoryLegendRow(category: MovementCategory, count: Int, total: Int) -> some View {
        let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0

        return HStack(spacing: 8) {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            Text(category.displayName)
                .font(.caption)
            Spacer()
            Text("\(Int(percentage))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
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
        VStack {
            HStack {
                Text(String(localized: "Exercises", bundle: .main))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }
            Divider()
        }
    }

    private var exerciseListContent: some View {
        VStack(spacing: 0) {
            if store.exerciseSummaries.isEmpty {
                Text(String(localized: "No exercises logged this month.", bundle: .main))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(store.exerciseSummaries) { summary in
                    exerciseRow(summary)
                    if summary.id != store.exerciseSummaries.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ summary: ExerciseSummary) -> some View {
        Button {
            send(.exerciseTapped(summary.exerciseType))
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(summary.category.color)
                    .frame(width: 8, height: 8)

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
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.count)\u{00D7}")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    exerciseWeightLabel(summary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func exerciseWeightLabel(_ summary: ExerciseSummary) -> some View {
        Group {
            if let maxWeight = summary.maxWeight, maxWeight > 0 {
                Text("\(maxWeight, specifier: "%.1f") kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text(String(localized: "BW", bundle: .main))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
