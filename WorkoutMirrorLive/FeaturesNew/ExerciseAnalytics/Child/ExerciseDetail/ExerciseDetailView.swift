//
//  ExerciseDetailView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import Charts
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
        .toolbar { dismissToolbarButton }
        .onAppear {
            send(.onAppear)
        }
        .navigationDestination(item: $store.scope(state: \.activityDetail, action: \.activityDetail)) { detailStore in
            ActivityDetailsView(store: detailStore)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var dismissToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.dismissTapped)
            } label: {
                Text(String(localized: "Done"))
                    .fontWeight(.semibold)
            }
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
        VStack {
            HStack {
                Text(String(localized: "Weight Progression"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Text("kg")
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
            }
            Divider()
        }
    }

    private var weightProgressionContent: some View {
        Group {
            if store.weightProgression.isEmpty {
                ChartContentUnavailable(
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: String(localized: "No weight data recorded for this exercise.")
                )
                .frame(height: 200)
            } else {
                weightProgressionChart
            }
        }
    }

    private var weightProgressionChart: some View {
        Chart {
            ForEach(store.weightProgression) { point in
                LineMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Weight"),
                        point.weight
                    )
                )
                .foregroundStyle(store.category.color.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Weight"),
                        point.weight
                    )
                )
                .foregroundStyle(store.category.color)
                .symbolSize(20)
            }

            if let pr = store.pr {
                RuleMark(y: .value("PR", pr))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(String(format: "PR: %.1f kg", pr))
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let kg = value.as(Double.self) {
                        Text(String(format: "%.0f", kg))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
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
        VStack {
            HStack {
                Text(String(localized: "Volume per Week"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Text(store.hasWeight ? "kg" : String(localized: "reps"))
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
            }
            Divider()
        }
    }

    private var volumePerWeekContent: some View {
        Group {
            if store.weeklyVolume.isEmpty {
                ChartContentUnavailable(
                    systemImage: "chart.bar.fill",
                    description: String(localized: "No volume data recorded for this exercise.")
                )
                .frame(height: 200)
            } else {
                volumePerWeekChart
            }
        }
    }

    private var volumePerWeekChart: some View {
        Chart {
            ForEach(store.weeklyVolume) { point in
                BarMark(
                    x: .value(
                        String(localized: "Week"),
                        point.week, unit: .weekOfYear
                    ),
                    y: .value(
                        String(localized: "Volume"),
                        point.volume
                    )
                )
                .foregroundStyle(store.category.color.gradient)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let vol = value.as(Double.self) {
                        Text(String(format: "%.0f", vol))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
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
        VStack {
            HStack {
                Text(String(localized: "Avg HR per Session"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Text("bpm")
                    .foregroundStyle(.tertiary)
                    .font(.caption2)
            }
            Divider()
        }
    }

    private var hrPerSessionContent: some View {
        Group {
            if store.hrPerSession.isEmpty {
                ChartContentUnavailable(
                    systemImage: "heart.fill",
                    description: String(localized: "No heart rate data recorded for this exercise.")
                )
                .frame(height: 200)
            } else {
                hrPerSessionChart
            }
        }
    }

    private var hrPerSessionChart: some View {
        Chart {
            ForEach(store.hrPerSession) { point in
                LineMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Avg HR"),
                        point.avgHR
                    )
                )
                .foregroundStyle(.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value(
                        String(localized: "Date"),
                        point.date
                    ),
                    y: .value(
                        String(localized: "Avg HR"),
                        point.avgHR
                    )
                )
                .foregroundStyle(.red)
                .symbolSize(20)
            }

            if let avg = store.avgHR {
                RuleMark(y: .value("Avg", avg))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(String(format: "%.0f bpm avg", avg))
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hr = value.as(Double.self) {
                        Text(String(format: "%.0f", hr))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
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

    private var historyContent: some View {
        VStack(spacing: 0) {
            if store.logs.isEmpty {
                Text(String(localized: "No history yet."))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(store.logs) { log in
                    historyRow(log)
                    if log.id != store.logs.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - History Row

    private func historyRow(_ log: ExerciseLog) -> some View {
        Group {
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
    }

    private func historyRowContent(_ log: ExerciseLog) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let wodName = log.wodName {
                    Text(wodName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
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

                HStack(spacing: 4) {
                    if log.isPR {
                        prBadge
                    }

                    if let hr = log.avgHeartRate {
                        hrLabel(hr)
                    }
                }
            }

            if log.workoutPlanScoreId != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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
