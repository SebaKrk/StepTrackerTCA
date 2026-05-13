//
//  ExerciseDetailView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ExerciseDetailFeature.self)
struct ExerciseDetailView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ExerciseDetailFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if !store.weightProgression.isEmpty {
                    weightProgressionCard
                }
                if store.weeklyVolume.contains(where: { $0.volume > 0 }) {
                    volumePerWeekCard
                }
                if !store.hrPerSession.isEmpty {
                    hrPerSessionCard
                }
                historyCard
            }
            .padding()
        }
        .navigationTitle(store.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            send(.onAppear)
        }
        .navigationDestination(item: $store.scope(state: \.activityDetail, action: \.activityDetail)) { detailStore in
            ActivityDetailsView(store: detailStore)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            dismissButton
        }
    }

    private var dismissButton: some View {
        Button {
            send(.dismissTapped)
        } label: {
            Text(String(localized: "Done"))
                .fontWeight(.semibold)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        GroupBox {
            headerContent
        } label: {
            headerLabel
        }
        .styledGroupBox()
    }

    private var headerLabel: some View {
        VStack {
            HStack {
                Circle()
                    .fill(store.category.color)
                    .frame(width: 10, height: 10)
                Text(store.category.displayName)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }
            Divider()
        }
    }

    private var headerContent: some View {
        HStack(spacing: 16) {
            headerMetric(
                title: String(localized: "Sessions"),
                value: "\(store.count)"
            )

            if store.hasWeight {
                headerMetric(
                    title: String(localized: "Weight"),
                    value: store.pr.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kg"
                )
            }

            headerMetric(
                title: String(localized: "Avg HR"),
                value: store.avgHR.map { String(format: "%.0f", $0) } ?? "—",
                unit: store.avgHR != nil ? "bpm" : ""
            )

            headerMetric(
                title: String(localized: "Max HR"),
                value: store.maxHR.map { String(format: "%.0f", $0) } ?? "—",
                unit: store.maxHR != nil ? "bpm" : ""
            )

            Spacer()
        }
    }

    private func headerMetric(title: String, value: String, unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Weight Progression Card

    private var weightProgressionCard: some View {
        GroupBox {
            weightProgressionContent
        } label: {
            weightProgressionHeader
        }
        .styledGroupBox()
    }

    private var weightProgressionHeader: some View {
        cardHeader(title: String(localized: "Weight Progression"), unit: "kg")
    }

    // MARK: - Volume per Week Card

    private var volumePerWeekCard: some View {
        GroupBox {
            volumePerWeekContent
        } label: {
            volumePerWeekHeader
        }
        .styledGroupBox()
    }

    private var volumePerWeekHeader: some View {
        cardHeader(
            title: String(localized: "Volume per Week"),
            unit: store.hasWeight ? "kg" : String(localized: "reps")
        )
    }

    // MARK: - HR per Session Card

    private var hrPerSessionCard: some View {
        GroupBox {
            hrPerSessionContent
        } label: {
            hrPerSessionHeader
        }
        .styledGroupBox()
    }

    private var hrPerSessionHeader: some View {
        cardHeader(title: String(localized: "Avg HR per Session"), unit: "bpm")
    }

    // MARK: - History Card

    private var historyCard: some View {
        GroupBox {
            historyContent
        } label: {
            historyHeader
        }
        .styledGroupBox()
    }

    private var historyHeader: some View {
        VStack {
            HStack {
                Text(String(localized: "History"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Text(String(format: String(localized: "%d sessions"), store.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if store.logs.isEmpty {
            historyEmpty
        } else {
            VStack(spacing: 0) {
                ForEach(store.logs) { log in
                    historyRow(log)
                    if log.id != store.logs.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var historyEmpty: some View {
        Text(String(localized: "No history yet."))
            .foregroundStyle(.secondary)
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    // MARK: - History Row

    @ViewBuilder
    private func historyRow(_ log: ExerciseLog) -> some View {
        if let scoreId = log.workoutPlanScoreId {
            Button {
                send(.historyRowTapped(scoreId))
            } label: {
                historyRowContent(log)
            }
            .buttonStyle(.plain)
        } else {
            historyRowContent(log)
        }
    }

    private func historyRowContent(_ log: ExerciseLog) -> some View {
        HStack(spacing: 12) {
            historyRowDateColumn(log)
            Spacer()
            historyRowMetricsColumn(log)
            historyRowChevron(log)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func historyRowDateColumn(_ log: ExerciseLog) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(log.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.subheadline)
                .fontWeight(.medium)
            historyRowWodName(log)
        }
    }

    @ViewBuilder
    private func historyRowWodName(_ log: ExerciseLog) -> some View {
        if let wodName = log.wodName {
            Text(wodName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func historyRowMetricsColumn(_ log: ExerciseLog) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            historyRowWeightReps(log)
            historyRowBadges(log)
        }
    }

    private func historyRowWeightReps(_ log: ExerciseLog) -> some View {
        HStack(spacing: 4) {
            if let weight = log.actualWeight {
                Text(String(format: "%.1f kg", weight))
                    .font(.caption)
                    .monospacedDigit()
            }
            if let reps = log.actualReps {
                Text(reps)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func historyRowBadges(_ log: ExerciseLog) -> some View {
        HStack(spacing: 4) {
            if log.isPR {
                prBadge
            }
            if let hr = log.avgHeartRate {
                hrLabel(hr)
            }
        }
    }

    @ViewBuilder
    private func historyRowChevron(_ log: ExerciseLog) -> some View {
        if log.workoutPlanScoreId != nil {
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Card Header Helper

    private func cardHeader(title: String, unit: String) -> some View {
        VStack {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Text(unit)
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
            }
            Divider()
        }
    }

    // MARK: - Badges

    private var prBadge: some View {
        Text("PR")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.orange, in: RoundedRectangle(cornerRadius: 4))
    }

    private func hrLabel(_ hr: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "heart.fill")
                .font(.caption2)
                .foregroundStyle(.red)
            Text(String(format: "%.0f", hr))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(
            date: calendar.date(byAdding: .day, value: -28, to: now)!,
            exerciseType: .backSquat,
            category: .strength,
            wodName: "Strength Monday",
            actualWeight: 100,
            actualReps: "5x5",
            isPR: false,
            avgHeartRate: 145,
            maxHeartRate: 168,
            volumeLoad: 2500
        ),
        ExerciseLog(
            date: calendar.date(byAdding: .day, value: -21, to: now)!,
            exerciseType: .backSquat,
            category: .strength,
            wodName: "Heavy Day",
            actualWeight: 105,
            actualReps: "5x5",
            isPR: false,
            avgHeartRate: 150,
            maxHeartRate: 172,
            volumeLoad: 2625
        ),
        ExerciseLog(
            date: calendar.date(byAdding: .day, value: -14, to: now)!,
            exerciseType: .backSquat,
            category: .strength,
            wodName: "Strength Monday",
            actualWeight: 110,
            actualReps: "5x3",
            isPR: false,
            avgHeartRate: 155,
            maxHeartRate: 175,
            volumeLoad: 1650
        ),
        ExerciseLog(
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            exerciseType: .backSquat,
            category: .strength,
            wodName: "PR Attempt",
            actualWeight: 120,
            actualReps: "1RM",
            scaling: .rx,
            isPR: true,
            avgHeartRate: 165,
            maxHeartRate: 185,
            volumeLoad: 120
        ),
        ExerciseLog(
            date: now,
            exerciseType: .backSquat,
            category: .strength,
            wodName: "Back Squat Day",
            actualWeight: 115,
            actualReps: "3x5",
            isPR: false,
            avgHeartRate: 152,
            maxHeartRate: 170,
            volumeLoad: 1725
        ),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .backSquat)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}

#Preview("Thrusters") {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(date: calendar.date(byAdding: .day, value: -25, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 40, actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 170, maxHeartRate: 182, volumeLoad: 1800),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -20, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 2", actualWeight: 40, actualReps: "15-12-9", scaling: .rx, isPR: false, avgHeartRate: 168, maxHeartRate: 180, volumeLoad: 1440),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -14, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 43, actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 165, maxHeartRate: 178, volumeLoad: 1935),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -10, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "Strength", actualWeight: 43, actualReps: "5-5-5", scaling: .rx, isPR: false, avgHeartRate: 155, maxHeartRate: 168, volumeLoad: 645),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -7, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 43, actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 158, maxHeartRate: 175, volumeLoad: 1935),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -1, to: now)!, exerciseType: .thrusters, category: .olympicLifting, wodName: "WOD 1", actualWeight: 45, actualReps: "21-15-9", scaling: .rx, isPR: true, avgHeartRate: 162, maxHeartRate: 178, volumeLoad: 2025),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .thrusters)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}

#Preview("Pull-ups (BW)") {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(date: calendar.date(byAdding: .day, value: -21, to: now)!, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 2", actualReps: "50", scaling: .scaled, isPR: false, avgHeartRate: 172, maxHeartRate: 185),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -14, to: now)!, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 1", actualReps: "75", scaling: .rx, isPR: false, avgHeartRate: 170, maxHeartRate: 182),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -7, to: now)!, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 1", actualReps: "45", scaling: .rx, isPR: false, avgHeartRate: 168, maxHeartRate: 180),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -1, to: now)!, exerciseType: .pullUps, category: .gymnastics, wodName: "WOD 2", actualReps: "100", scaling: .rx, isPR: true, avgHeartRate: 175, maxHeartRate: 188),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .pullUps)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}

#Preview("Front Squat (Strength)") {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(date: calendar.date(byAdding: .day, value: -28, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "Strength", actualWeight: 80, actualReps: "5-5-5-5-5", scaling: .rx, isPR: false, avgHeartRate: 145, maxHeartRate: 160, volumeLoad: 2000),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -21, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "Strength", actualWeight: 85, actualReps: "5-5-5-5-5", scaling: .rx, isPR: false, avgHeartRate: 150, maxHeartRate: 165, volumeLoad: 2125),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -14, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "Strength", actualWeight: 90, actualReps: "5-5-5-5-5", scaling: .rx, isPR: false, avgHeartRate: 152, maxHeartRate: 170, volumeLoad: 2250),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -7, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "Strength", actualWeight: 95, actualReps: "5-5-5-5-3", scaling: .rx, isPR: false, avgHeartRate: 158, maxHeartRate: 175, volumeLoad: 2185),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -3, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "Strength", actualWeight: 100, actualReps: "5-5-5-5-5", scaling: .rx, isPR: true, avgHeartRate: 155, maxHeartRate: 172, volumeLoad: 2500),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -1, to: now)!, exerciseType: .frontSquat, category: .strength, wodName: "WOD", actualWeight: 70, actualReps: "15-12-9", scaling: .rx, isPR: false, avgHeartRate: 168, maxHeartRate: 182, volumeLoad: 2520),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .frontSquat)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}

#Preview("Burpees (BW, high volume)") {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(date: calendar.date(byAdding: .day, value: -27, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "30", scaling: .rx, isPR: false, avgHeartRate: 170, maxHeartRate: 185),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -24, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 2", actualReps: "50", scaling: .rx, isPR: false, avgHeartRate: 175, maxHeartRate: 190),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -20, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 172, maxHeartRate: 188),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -17, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 3", actualReps: "100", scaling: .rx, isPR: false, avgHeartRate: 178, maxHeartRate: 192),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -13, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "30", scaling: .rx, isPR: false, avgHeartRate: 168, maxHeartRate: 184),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -10, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 2", actualReps: "50", scaling: .rx, isPR: false, avgHeartRate: 165, maxHeartRate: 182),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -6, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 1", actualReps: "21-15-9", scaling: .rx, isPR: false, avgHeartRate: 162, maxHeartRate: 180),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -2, to: now)!, exerciseType: .burpees, category: .mixed, wodName: "WOD 2", actualReps: "75", scaling: .rx, isPR: true, avgHeartRate: 160, maxHeartRate: 178),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .burpees)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}

#Preview("HSPU (Scaled → Rx)") {
    let now = Date()
    let calendar = Calendar.current
    let logs: [ExerciseLog] = [
        ExerciseLog(date: calendar.date(byAdding: .day, value: -25, to: now)!, exerciseType: .handstandPushUps, category: .gymnastics, wodName: "WOD 1", actualReps: "15", scaling: .scaled, isPR: false, avgHeartRate: 155, maxHeartRate: 168),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -18, to: now)!, exerciseType: .handstandPushUps, category: .gymnastics, wodName: "WOD 2", actualReps: "20", scaling: .scaled, isPR: false, avgHeartRate: 158, maxHeartRate: 172),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -11, to: now)!, exerciseType: .handstandPushUps, category: .gymnastics, wodName: "WOD 1", actualReps: "15", scaling: .rx, isPR: false, avgHeartRate: 162, maxHeartRate: 178),
        ExerciseLog(date: calendar.date(byAdding: .day, value: -4, to: now)!, exerciseType: .handstandPushUps, category: .gymnastics, wodName: "WOD 3", actualReps: "25", scaling: .rx, isPR: true, avgHeartRate: 160, maxHeartRate: 175),
    ]
    var state = ExerciseDetailFeature.State(exerciseType: .handstandPushUps)
    state.logs = logs
    return NavigationStack {
        ExerciseDetailView(store: Store(initialState: state) {
            ExerciseDetailFeature()
        } withDependencies: {
            $0.exerciseLogClient.fetchByExerciseType = { _ in logs }
        })
    }
}
