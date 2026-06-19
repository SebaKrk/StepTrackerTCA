//
//  ClassHistoryDetailView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

/// Detail view klasy w History — push z `ClassHistoryView` row tap. 4 sekcje:
/// top stats banner, HR chart (per athlete / combined toggle), calories bar,
/// time in zones pie.
@ViewAction(for: ClassHistoryDetailFeature.self)
struct ClassHistoryDetailView: View {

    @Bindable var store: StoreOf<ClassHistoryDetailFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                topStatsBanner
                hrChartSection
                if !store.athletes.isEmpty {
                    caloriesSection
                }
            }
            .padding()
        }
        .navigationTitle(store.className)
        .navigationBarTitleDisplayMode(.large)
        .task { send(.viewDidAppear) }
    }

    // MARK: - Top stats banner

    private var topStatsBanner: some View {
        HStack(spacing: 12) {
            statCard(label: athletesLabel, value: "\(store.athletes.count)")
            statCard(label: durationLabelTitle, value: durationValue)
            statCard(label: caloriesLabel, value: caloriesValue)
            statCard(label: avgHRLabel, value: avgHRValue)
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - HR chart section (toggle per athlete / combined)

    private var hrChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(hrSectionTitle)
                    .font(.headline)
                Spacer()
            }
            chartModePicker
            chartContent
        }
    }

    private var chartModePicker: some View {
        Picker(hrSectionTitle, selection: $store.chartViewMode) {
            ForEach(ClassHistoryDetailFeature.ChartViewMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartContent: some View {
        if store.athletes.isEmpty {
            emptyHRChart
        } else {
            switch store.chartViewMode {
            case .combined: combinedChart
            case .perAthlete: perAthleteCards
            }
        }
    }

    private var emptyHRChart: some View {
        ContentUnavailableView(
            emptyChartTitle,
            systemImage: "waveform.path.ecg",
            description: Text(emptyChartDescription)
        )
        .frame(height: 200)
    }

    /// Multi-series line chart — wszyscy athletes na jednej skali czasu z legendą.
    private var combinedChart: some View {
        Chart {
            ForEach(store.athletes) { athlete in
                ForEach(athlete.samples, id: \.timestamp) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("BPM", sample.bpm),
                        series: .value("Athlete", athlete.nick)
                    )
                    .foregroundStyle(by: .value("Athlete", athlete.nick))
                    .interpolationMethod(.monotone)
                }
            }
        }
        .chartLegend(position: .bottom, alignment: .leading)
        .frame(height: 280)
    }

    /// Lista kart per athlete — każda karta = mini line chart + stats label.
    private var perAthleteCards: some View {
        VStack(spacing: 12) {
            ForEach(store.athletes) { athlete in
                athleteCard(for: athlete)
            }
        }
    }

    private func athleteCard(for athlete: AthleteSummary) -> some View {
        let color = AthleteColor.color(for: athlete.deviceID)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(athlete.nick)
                    .font(.headline)
                Spacer()
                Text(athleteStatsLabel(for: athlete))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Chart(athlete.samples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(color)
                .interpolationMethod(.monotone)
            }
            .frame(height: 100)
        }
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Calories bar chart

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(caloriesSectionTitle)
                .font(.headline)
            Chart {
                ForEach(sortedByCalories) { athlete in
                    BarMark(
                        x: .value("kcal", athlete.analytics.totalCalories),
                        y: .value("Athlete", athlete.nick)
                    )
                    .foregroundStyle(AthleteColor.color(for: athlete.deviceID))
                    .annotation(position: .trailing) {
                        Text(String(format: "%.1f", athlete.analytics.totalCalories))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: CGFloat(store.athletes.count * 40 + 40))
        }
    }

    // MARK: - Private content (implementacja)

    private var athletesLabel: String {
        String(localized: "Athletes", bundle: .main)
    }

    private var durationLabelTitle: String {
        String(localized: "Duration", bundle: .main)
    }

    private var caloriesLabel: String {
        String(localized: "Calories", bundle: .main)
    }

    private var avgHRLabel: String {
        String(localized: "Avg HR", bundle: .main)
    }

    private var hrSectionTitle: String {
        String(localized: "HR over time", bundle: .main)
    }

    private var caloriesSectionTitle: String {
        String(localized: "Calories burned", bundle: .main)
    }

    private var emptyChartTitle: String {
        String(localized: "No athletes data", bundle: .main)
    }

    private var emptyChartDescription: String {
        String(localized: "This class had no peers connected.", bundle: .main)
    }

    // MARK: - Computed values

    private var durationValue: String {
        guard let endedAt = store.endedAt else {
            return String(localized: "Ongoing", bundle: .main)
        }
        let seconds = Int(endedAt.timeIntervalSince(store.startedAt))
        return formattedDuration(seconds)
    }

    private var caloriesValue: String {
        let total = store.athletes.reduce(0.0) { $0 + $1.analytics.totalCalories }
        return String(format: "%.1f", total)
    }

    private var avgHRValue: String {
        guard !store.athletes.isEmpty else { return "—" }
        let sum = store.athletes.reduce(0) { $0 + $1.analytics.avgHR }
        return "\(sum / store.athletes.count)"
    }

    private var sortedByCalories: [AthleteSummary] {
        store.athletes.sorted { $0.analytics.totalCalories > $1.analytics.totalCalories }
    }

    private func athleteStatsLabel(for athlete: AthleteSummary) -> String {
        "avg \(athlete.analytics.avgHR) · peak \(athlete.analytics.peakHR)"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}
