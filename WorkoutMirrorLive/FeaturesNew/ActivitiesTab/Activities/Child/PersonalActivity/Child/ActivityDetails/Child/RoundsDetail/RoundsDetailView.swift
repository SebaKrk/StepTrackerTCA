//
//  RoundsDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 09/09/2026.
//

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

/// Rounds analysis screen: a stat grid plus two charts in the language of the
/// minute-by-minute HR chart — capsule bars with a zone gradient anchored to
/// the HR value, colors classified against the USER max HR.
@ViewAction(for: RoundsDetailFeature.self)
struct RoundsDetailView: View {

    let store: StoreOf<RoundsDetailFeature>

    var body: some View {
        content
            .padding([.leading, .trailing], 8)
            .navigationTitle(String(localized: "Rounds"))
            .background(backgroundGradient.ignoresSafeArea())
            .onAppear { send(.viewDidAppear) }
    }

    // MARK: - Structure

    @ViewBuilder
    private var content: some View {
        if let analysis = store.analysis {
            analysisBody(analysis)
        } else if store.isLoading {
            loadingPlaceholder
        } else {
            emptyPlaceholder
        }
    }

    private func analysisBody(_ analysis: RoundsAnalysis) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                statGrid(analysis)
                rangesCard(analysis)
                if !analysis.recoveries.isEmpty {
                    recoveryCard(analysis)
                }
                if !store.hrCurve.isEmpty {
                    curveCard
                }
            }
        }
    }

    private func statGrid(_ analysis: RoundsAnalysis) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
            statCard(String(localized: "Rounds"), value: "\(analysis.rounds.count)")
            statCard(String(localized: "Avg round HR"), value: "\(analysis.averageWorkHR)", unit: "bpm")
            statCard(
                String(localized: "Avg recovery"),
                value: analysis.averageDrop.map { "−\($0)" } ?? "—",
                unit: analysis.averageDrop != nil ? "bpm" : nil
            )
            statCard(
                String(localized: "Hardest round"),
                value: analysis.hardestRound.map { "\($0.index)" } ?? "—",
                unit: analysis.hardestRound.map { "\($0.peakHR) bpm" }
            )
        }
    }

    private func rangesCard(_ analysis: RoundsAnalysis) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                cardTitle(String(localized: "HR range per round"))
                rangesChart(analysis)
                if let trend = averageTrend(analysis) {
                    cardFooter(String(localized: "Avg trend"), value: trend)
                }
            }
        }
        .styledGroupBox()
    }

    private func recoveryCard(_ analysis: RoundsAnalysis) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                cardTitle(String(localized: "Recovery between rounds"))
                recoveryChart(analysis)
                if let fadeRound = analysis.recoveryFadeAfterRound {
                    cardFooter(
                        String(localized: "Recovery fades after round"),
                        value: "\(fadeRound)"
                    )
                }
            }
        }
        .styledGroupBox()
    }

    private var curveCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                cardTitle(String(localized: "HR × rounds"))
                curveChart
            }
        }
        .styledGroupBox()
    }

    // MARK: - Implementation (charts)

    /// Whole-block HR curve with a band under every round — green means BOX,
    /// same traffic-light convention as the live timer tile.
    private var curveChart: some View {
        Chart {
            ForEach(store.segments.filter { $0.kind == .work }, id: \.dateInterval.start) { segment in
                RectangleMark(
                    xStart: .value("Round start", segment.dateInterval.start),
                    xEnd: .value("Round end", segment.dateInterval.end)
                )
                .foregroundStyle(IntervalTimerFeature.State.workAccent.opacity(0.14))
            }
            ForEach(store.hrCurve, id: \.date) { sample in
                LineMark(
                    x: .value("Time", sample.date),
                    y: .value("HR", sample.bpm)
                )
                .foregroundStyle(.white)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 180)
        .padding(.vertical, 4)
    }

    /// Min–peak capsule per round with the zone gradient; white dot = average.
    private func rangesChart(_ analysis: RoundsAnalysis) -> some View {
        Chart(analysis.rounds) { round in
            BarMark(
                x: .value("Round", "\(round.index)"),
                yStart: .value("HR min", round.minHR),
                // Same floor as the minute chart — a flat round stays visible.
                yEnd: .value("HR max", max(round.peakHR, round.minHR + 2)),
                width: .ratio(0.55)
            )
            .foregroundStyle(zoneGradient(from: round.minHR, to: round.peakHR))
            .cornerRadius(8)

            PointMark(
                x: .value("Round", "\(round.index)"),
                y: .value("HR avg", round.avgHR)
            )
            .foregroundStyle(.white)
            .symbolSize(24)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 200)
        .padding(.vertical, 4)
    }

    /// BPM given back in each rest — taller bar = better recovery. Bar color =
    /// the ZONE the athlete recovered to (HR at the rest's end), so the palette
    /// means exactly what it means everywhere else in the app.
    private func recoveryChart(_ analysis: RoundsAnalysis) -> some View {
        Chart(analysis.recoveries) { recovery in
            BarMark(
                x: .value("After round", "\(recovery.afterRound)"),
                y: .value("Drop", recovery.dropBPM),
                width: .ratio(0.55)
            )
            .foregroundStyle(zoneColor(for: recovery.endHR))
            .cornerRadius(8)
        }
        .frame(height: 150)
        .padding(.vertical, 4)
    }

    // MARK: - Implementation (cards & placeholders)

    private func statCard(_ title: String, value: String, unit: String? = nil) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    if let unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func cardFooter(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value)
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.top, 2)
    }

    private var loadingPlaceholder: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyPlaceholder: some View {
        ContentUnavailableView(
            String(localized: "No heart rate data"),
            systemImage: "heart.slash",
            description: Text(String(localized: "No heart rate samples were recorded during these rounds."))
        )
    }

    // MARK: - Implementation (colors & formatting)

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// "148 → 172 bpm" — first vs last round average.
    private func averageTrend(_ analysis: RoundsAnalysis) -> String? {
        guard let first = analysis.rounds.first, let last = analysis.rounds.last,
              analysis.rounds.count > 1
        else { return nil }
        let arrow = last.avgHR > first.avgHR ? " ▲" : (last.avgHR < first.avgHR ? " ▼" : "")
        return "\(first.avgHR) → \(last.avgHR) bpm\(arrow)"
    }

    /// Same vertical zone gradient as the minute chart — value-based colors.
    private func zoneGradient(from minHR: Int, to peakHR: Int) -> LinearGradient {
        LinearGradient(
            colors: [zoneColor(for: minHR), zoneColor(for: peakHR)],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func zoneColor(for bpm: Int) -> Color {
        HeartRateZone.zone(bpm: bpm, maxHR: Int(store.maxHeartRate)).color
    }
}
