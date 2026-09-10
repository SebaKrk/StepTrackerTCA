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
                cardHeader(String(localized: "HR range per round"), info: .ranges)
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
                cardHeader(String(localized: "Recovery between rounds"), info: .recovery)
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
                cardHeader(String(localized: "HR × rounds"), info: .curve)
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
            roundBands
            curveSelectionMark
            heartRateLine
        }
        .chartXSelection(value: curveSelectionBinding)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 180)
        .padding(.vertical, 4)
    }

    // MARK: - Implementation (chart marks)

    private func roundRangeBars(_ analysis: RoundsAnalysis) -> some ChartContent {
        ForEach(analysis.rounds) { round in
            BarMark(
                x: .value("Round", "\(round.index)"),
                yStart: .value("HR min", round.minHR),
                // Same floor as the minute chart — a flat round stays visible.
                yEnd: .value("HR max", max(round.peakHR, round.minHR + 2)),
                width: .ratio(0.55)
            )
            .foregroundStyle(zoneGradient(from: round.minHR, to: round.peakHR))
            .cornerRadius(8)
            .opacity(store.selectedRound == nil || store.selectedRound == round.index ? 1 : 0.5)

            PointMark(
                x: .value("Round", "\(round.index)"),
                y: .value("HR avg", round.avgHR)
            )
            .foregroundStyle(.white)
            .symbolSize(24)
        }
    }

    @ChartContentBuilder
    private func roundSelectionMark(_ analysis: RoundsAnalysis) -> some ChartContent {
        if let selected = analysis.rounds.first(where: { $0.index == store.selectedRound }) {
            RuleMark(x: .value("Round", "\(selected.index)"))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .offset(y: -30)
                .annotation(
                    position: .bottomTrailing,
                    spacing: 4,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    roundAnnotation(selected)
                }
        }
    }

    private func recoveryBars(_ analysis: RoundsAnalysis) -> some ChartContent {
        ForEach(analysis.recoveries) { recovery in
            BarMark(
                x: .value("After round", "\(recovery.afterRound)"),
                // yStart/yEnd form — a zero-anchored bar keeps a square base,
                // this one rounds BOTH ends like the ranges capsules.
                yStart: .value("Drop", 0),
                yEnd: .value("Drop", recovery.dropBPM),
                width: .ratio(0.55)
            )
            .foregroundStyle(recoveryGradient(for: recovery))
            .cornerRadius(8)
            .opacity(store.selectedRecovery == nil || store.selectedRecovery == recovery.afterRound ? 1 : 0.5)
        }
    }

    @ChartContentBuilder
    private func recoverySelectionMark(_ analysis: RoundsAnalysis) -> some ChartContent {
        if let selected = analysis.recoveries.first(where: { $0.afterRound == store.selectedRecovery }) {
            RuleMark(x: .value("After round", "\(selected.afterRound)"))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .offset(y: -30)
                .annotation(
                    position: .bottomTrailing,
                    spacing: 4,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    recoveryAnnotation(selected)
                }
        }
    }

    private var roundBands: some ChartContent {
        ForEach(store.segments.filter { $0.kind == .work }, id: \.dateInterval.start) { segment in
            RectangleMark(
                xStart: .value("Round start", segment.dateInterval.start),
                xEnd: .value("Round end", segment.dateInterval.end)
            )
            .foregroundStyle(IntervalTimerFeature.State.workAccent.opacity(0.14))
        }
    }

    @ChartContentBuilder
    private var curveSelectionMark: some ChartContent {
        if let selectedDate = store.selectedCurveDate, let sample = curveSample(at: selectedDate) {
            RuleMark(x: .value("Time", sample.date))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .offset(y: -30)
                .annotation(
                    position: .bottomTrailing,
                    spacing: 4,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    curveAnnotation(sample)
                }
        }
    }

    private var heartRateLine: some ChartContent {
        ForEach(store.hrCurve, id: \.date) { sample in
            LineMark(
                x: .value("Time", sample.date),
                y: .value("HR", sample.bpm)
            )
            .foregroundStyle(Color.primary)
            .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.monotone)
        }
    }

    // MARK: - Implementation (selection & annotations)

    private var roundSelectionBinding: Binding<String?> {
        Binding(
            get: { store.selectedRound.map(String.init) },
            set: { send(.roundSelected($0.flatMap(Int.init)), animation: .easeInOut) }
        )
    }

    private var recoverySelectionBinding: Binding<String?> {
        Binding(
            get: { store.selectedRecovery.map(String.init) },
            set: { send(.recoverySelected($0.flatMap(Int.init)), animation: .easeInOut) }
        )
    }

    private var curveSelectionBinding: Binding<Date?> {
        Binding(
            get: { store.selectedCurveDate },
            set: { send(.curveDateSelected($0), animation: .easeInOut) }
        )
    }

    private func roundAnnotation(_ round: RoundsAnalysis.Round) -> some View {
        annotationCard {
            HStack(spacing: 4) {
                Text("Round \(round.index)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: "· \(durationLabel(round.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text(verbatim: "\(round.minHR)–\(round.peakHR)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text("avg \(round.avgHR)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text(zone(for: round.avgHR).title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(zone(for: round.avgHR).color)
                if let kcal = round.kcal {
                    Text(verbatim: "· \(Int(kcal.rounded())) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func recoveryAnnotation(_ recovery: RoundsAnalysis.Recovery) -> some View {
        annotationCard {
            HStack(spacing: 4) {
                Text("After round \(recovery.afterRound)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: "· \(durationLabel(recovery.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text(verbatim: "−\(recovery.dropBPM) bpm")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text(verbatim: "(\(recovery.peakHR) → \(recovery.endHR))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if let kcal = recovery.kcal {
                Text(verbatim: "\(Int(kcal.rounded())) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func curveAnnotation(_ sample: (date: Date, bpm: Double)) -> some View {
        annotationCard {
            HStack(spacing: 4) {
                Text(sample.date, format: .dateTime.hour().minute().second())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: "· \(Int(sample.bpm.rounded())) bpm")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
            }
            Text(curveContext(at: sample.date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func annotationCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func curveSample(at date: Date) -> (date: Date, bpm: Double)? {
        store.hrCurve.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func curveContext(at date: Date) -> String {
        guard let segment = store.segments.first(where: { $0.dateInterval.contains(date) }) else {
            return String(localized: "Outside rounds")
        }
        return segment.kind == .work
            ? String(localized: "Round \(segment.roundIndex)")
            : String(localized: "After round \(segment.roundIndex)")
    }

    private func zone(for bpm: Int) -> HeartRateZone {
        HeartRateZone.zone(bpm: bpm, maxHR: Int(store.maxHeartRate))
    }

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return total < 60 ? "\(total) s" : String(format: "%d:%02d", total / 60, total % 60)
    }

    /// Min–peak capsule per round with the zone gradient; white dot = average.
    private func rangesChart(_ analysis: RoundsAnalysis) -> some View {
        Chart {
            roundRangeBars(analysis)
            roundSelectionMark(analysis)
        }
        // Category axis: the domain order MUST be pinned to the data — otherwise
        // the selection RuleMark re-declares its category first and the tapped
        // bar jumps to the leading edge.
        .chartXScale(domain: analysis.rounds.map { "\($0.index)" })
        .chartXSelection(value: roundSelectionBinding)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 200)
        .padding(.vertical, 4)
    }

    /// BPM given back in each rest — taller bar = better recovery. Bar color =
    /// the ZONE the athlete recovered to (HR at the rest's end), so the palette
    /// means exactly what it means everywhere else in the app.
    private func recoveryChart(_ analysis: RoundsAnalysis) -> some View {
        Chart {
            recoveryBars(analysis)
            recoverySelectionMark(analysis)
        }
        // Same category-domain pin as the ranges chart — see comment there.
        .chartXScale(domain: analysis.recoveries.map { "\($0.afterRound)" })
        .chartXSelection(value: recoverySelectionBinding)
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

    private func cardHeader(_ title: String, info: RoundsDetailFeature.State.ChartInfo) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            infoButton(for: info)
        }
    }

    /// (i) in the card's top-right corner — a short "how to read this" popover.
    private func infoButton(for info: RoundsDetailFeature.State.ChartInfo) -> some View {
        Button {
            send(.infoChanged(info))
        } label: {
            Image(systemName: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentShape(Circle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .popover(isPresented: infoBinding(info)) {
            infoText(explanation(for: info))
        }
    }

    private func infoBinding(_ info: RoundsDetailFeature.State.ChartInfo) -> Binding<Bool> {
        Binding(
            get: { store.visibleInfo == info },
            set: { isPresented in send(.infoChanged(isPresented ? info : nil)) }
        )
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.primary)
            .padding(14)
            .frame(maxWidth: 300)
            .presentationCompactAdaptation(.popover)
    }

    private func explanation(for info: RoundsDetailFeature.State.ChartInfo) -> String {
        switch info {
        case .ranges:
            return String(localized: "Each capsule spans the round's min–max heart rate, the dot marks its average. Colors follow your heart-rate zones — the redder the round, the harder it was.")
        case .recovery:
            return String(localized: "How many beats your heart rate dropped in each rest — from the peak around the round's end to the rest's end. Colors run from the peak's zone (top) to the zone you recovered to (bottom); shrinking bars mean accumulating fatigue.")
        case .curve:
            return String(localized: "Your full heart-rate curve over the whole block. Green bands are the rounds, the gaps between them are the rests.")
        }
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

    /// Training-zones language (same convention as the zones card): a rest that
    /// lands BELOW zone 1 still reads as zone 1 — resting gray would look like
    /// "no data" while it actually means the best possible recovery.
    private func recoveryZoneColor(for bpm: Int) -> Color {
        let zone = HeartRateZone.zone(bpm: bpm, maxHR: Int(store.maxHeartRate))
        return zone == .resting ? HeartRateZone.recovery.color : zone.color
    }

    /// The bar height stays the drop VALUE; the colors tell the journey —
    /// from the peak's zone (top) down to the zone recovered to (bottom).
    private func recoveryGradient(for recovery: RoundsAnalysis.Recovery) -> LinearGradient {
        LinearGradient(
            colors: [
                recoveryZoneColor(for: recovery.endHR),
                recoveryZoneColor(for: recovery.peakHR)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
