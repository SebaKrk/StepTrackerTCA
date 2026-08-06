//
//  HRMirrorView.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI
import WatchKit

/// Displays live heart rate data mirrored from the paired iPhone workout session.
///
/// Shows:
/// - Current BPM in the zone color
/// - Zone label
/// - Elapsed workout time
@ViewAction(for: HRMirrorFeature.self)
struct HRMirrorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<HRMirrorFeature>

    // MARK: - View

    var body: some View {
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) }
        )) {
            controlsTab.tag(HRMirrorFeature.Tab.controls)
            hrTab.tag(HRMirrorFeature.Tab.hr)
            NowPlayingView().tag(HRMirrorFeature.Tab.music)
        }
        .tabViewStyle(.page(indexDisplayMode: store.showTabIndicator ? .automatic : .never))
        .onTapGesture {
            send(.screenTapped)
        }
        .onAppear {
            send(.onAppear)
        }
        .toolbar(.hidden)
        .overlay {
            if store.isSaving {
                savingOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            } else if case .presented(let summary) = store.summaryPhase {
                summaryOverlay(summary)
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            } else if store.isCountingDown {
                countdownOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.isSaving)
        .animation(.easeInOut(duration: 0.4), value: store.summaryPhase)
        .animation(.easeInOut(duration: 0.3), value: store.isCountingDown)
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("\(store.countdownRemaining)")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(.pink)
                .contentTransition(.numericText(countsDown: true))
                .animation(.easeInOut, value: store.countdownRemaining)
        }
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                savingIcon
                savingLabel
            }
        }
    }

    private var savingIcon: some View {
        ProgressView()
            .controlSize(.large)
    }

    private var savingLabel: some View {
        Text(String(localized: "Saving…"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Summary Overlay

    /// Post-save mini-summary (IOS-00098-D). Watch is the primary session owner,
    /// so it confirms the save immediately — metrics come straight from
    /// `finishWorkout()`, no HealthKit query, no dependency on iPhone reachability.
    ///
    /// Layout mirrors the legacy `TrainingSummaryView` (MyFitnessJournal Watch App):
    /// left-aligned metric blocks — title + large rounded small-caps value + divider —
    /// in a ScrollView, with Done at the bottom.
    private func summaryOverlay(_ summary: WatchWorkoutSummary?) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading) {
                    summaryTitle(hasData: summary != nil)
                    if let summary {
                        summaryMetric(
                            title: String(localized: "Total Time"),
                            value: Duration.seconds(summary.duration)
                                .formatted(.time(pattern: .hourMinuteSecond)),
                            .yellow
                        )
                        summaryMetric(
                            title: String(localized: "Total Energy"),
                            value: Measurement(value: summary.activeEnergyKcal, unit: UnitEnergy.kilocalories)
                                .formatted(.measurement(
                                    width: .abbreviated,
                                    usage: .workout,
                                    numberFormatStyle: .number.precision(.fractionLength(0))
                                )),
                            .pink
                        )
                        summaryMetric(
                            title: String(localized: "Avg. Heart Rate"),
                            value: summary.averageHeartRate
                                .formatted(.number.precision(.fractionLength(0))) + " bpm",
                            .red
                        )
                        // Effort points come from the live accumulator (kept in
                        // state through the summary phase), not from the saved
                        // workout — HealthKit's summary has no notion of them.
                        summaryMetric(
                            title: String(localized: "Effort Points"),
                            value: store.effortPoints.points.formatted(.number) + " " + String(localized: "pts"),
                            .yellow
                        )
                    } else {
                        summaryUnavailableLabel
                    }
                    summaryDoneButton
                }
            }
            .padding(.horizontal, 4)
        }
    }

    /// Green "Workout saved" only when we actually hold the saved workout's data —
    /// with no data the save is unconfirmed, and claiming success would be the same
    /// false-positive this ticket removes elsewhere (IOS-00098).
    private func summaryTitle(hasData: Bool) -> some View {
        Label {
            Text(hasData
                 ? String(localized: "Workout saved")
                 : String(localized: "Workout ended"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: hasData ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(hasData ? .green : .orange)
        }
        .padding(.bottom, 4)
    }

    /// Metric block in the legacy `SummaryMetricView` style: plain title,
    /// large rounded small-caps value in the metric color, divider below.
    @ViewBuilder
    private func summaryMetric(title: String, value: String, _ valueColor: Color) -> some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
            .foregroundStyle(valueColor)
        Divider()
    }

    private var summaryUnavailableLabel: some View {
        Text(String(localized: "Workout data unavailable"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private var summaryDoneButton: some View {
        Button {
            send(.summaryDoneTapped)
        } label: {
            Text(String(localized: "Done"))
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }

    // MARK: - Controls Tab

    private var controlsTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(spacing: 12) {
                VStack {
                    pauseResumeButton
                    pauseResumeLabel
                }
                VStack {
                    stopButton
                    stopButtonLabel
                }
            }
        }
    }

    private var pauseResumeButton: some View {
        Button {
            send(.pauseResumeTapped)
        } label: {
            pauseResumeIcon
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    }

    private var pauseResumeIcon: some View {
        Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
            .font(.system(size: 26, weight: .semibold))
    }

    private var pauseResumeLabel: some View {
        Text(store.isPaused ? String(localized: "Resume") : String(localized: "Pause"))
            .font(.caption.weight(.semibold))
    }

    private var stopButton: some View {
        Button {
            // No-op — short tap intentionally does nothing.
            // Confirmation requires 1.5 s long-press to prevent accidental taps during workout.
        } label: {
            stopButtonIcon
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.5)
                .onEnded { _ in
                    WKInterfaceDevice.current().play(.success)
                    send(.stopLongPressConfirmed)
                }
        )
    }

    private var stopButtonIcon: some View {
        Image(systemName: "stop.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.red)
    }

    private var stopButtonLabel: some View {
        Text(String(localized: "Stop"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red)
    }

    // MARK: - HR Tab

    private var hrZonePercentage: Int {
        guard store.maxHeartRate > 0 else { return 0 }
        return min(Int(Double(store.heartRate) / Double(store.maxHeartRate) * 100), 100)
    }

    private var hrTab: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                hrContent
            }
            .overlay(alignment: .topLeading) {
                zonePercentageLabel
            }
            .overlay(alignment: .top) {
                effortPointsLabel
            }
            .overlay {
                zoneBorderOverlay(cornerRadius: geometry.size.width * 0.24)
            }
        }
    }

    private var hrContent: some View {
        VStack(spacing: 4) {
            Spacer()
            heartRateView
            zoneLabel
            Spacer()
            elapsedTimeView
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var zonePercentageLabel: some View {
        Text("\(hrZonePercentage)%")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(store.heartRateZone.color)
            .monospacedDigit()
            .padding(.leading, 24)
            .padding(.top, 16)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: store.heartRateZone)
    }

    private func zoneBorderOverlay(cornerRadius: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 1)
                .strokeBorder(store.heartRateZone.color.opacity(0.6), lineWidth: 1)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: store.heartRateZone)

            Capsule(style: .continuous)
                .fill(Color.black)
                .frame(width: 56, height: 18)
                .offset(y: 4)
                .ignoresSafeArea()
        }
    }

    // MARK: - Subviews

    private var heartRateView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .symbolEffect(.bounce, options: .repeat(.continuous))

            Text("\(store.heartRate)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(store.heartRateZone.color)
                .monospacedDigit()

            Text("BPM")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private var zoneLabel: some View {
        Text(store.heartRateZone.title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(store.heartRateZone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(store.heartRateZone.color.opacity(0.2), in: Capsule())
    }

    /// Live effort points (Myzone-style) — top-center, between the `%HR` label
    /// (top-leading) and the system clock (top-trailing, off-limits on watchOS).
    private var effortPointsLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)
            Text("\(store.effortPoints.points)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(store.effortPoints.points)))
                .animation(.snappy(duration: 0.3), value: store.effortPoints.points)
            Text(String(localized: "pts"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        // Same top inset as `zonePercentageLabel` so both sit on one horizontal line.
        .padding(.top, 16)
        .ignoresSafeArea()
    }

    private var elapsedTimeView: some View {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 1.0 / 30.0)) { context in
            ElapsedTimeView(
                elapsedTime: store.elapsedSeconds,
                showSubseconds: context.cadence == .live
            )
            .font(.system(size: 28, design: .rounded).monospacedDigit())
            .foregroundStyle(.yellow)
        }
    }

}

// MARK: - Preview

#Preview("Resting") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 185, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 60
        state.heartRateZone = .resting
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Zone 1") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 623, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 98
        state.heartRateZone = .recovery
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Zone 2") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 1240, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 117
        state.heartRateZone = .fatBurning
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Zone 3") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 2105, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 138
        state.heartRateZone = .aerobic
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Zone 4") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 3421, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 158
        state.heartRateZone = .threshold
        // ~57 min across zones — effort points counter shows a realistic total.
        for _ in 0..<12 { state.effortPoints.add(bpm: 120, duration: 60, maxHR: 185) }
        for _ in 0..<25 { state.effortPoints.add(bpm: 140, duration: 60, maxHR: 185) }
        for _ in 0..<20 { state.effortPoints.add(bpm: 158, duration: 60, maxHR: 185) }
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Zone 5") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 4812, maxHeartRate: 185)
        state.isCountingDown = false
        state.heartRate = 177
        state.heartRateZone = .anaerobic
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Summary") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 2105, maxHeartRate: 185)
        state.isCountingDown = false
        state.summaryPhase = .presented(
            WatchWorkoutSummary(duration: 2105, activeEnergyKcal: 412, averageHeartRate: 132)
        )
        // ~35 min across zones — Effort Points row shows a realistic total.
        for _ in 0..<10 { state.effortPoints.add(bpm: 120, duration: 60, maxHR: 185) }
        for _ in 0..<15 { state.effortPoints.add(bpm: 145, duration: 60, maxHR: 185) }
        for _ in 0..<10 { state.effortPoints.add(bpm: 165, duration: 60, maxHR: 185) }
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Summary — long workout") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 4356, maxHeartRate: 185)
        state.isCountingDown = false
        state.summaryPhase = .presented(
            WatchWorkoutSummary(duration: 4356, activeEnergyKcal: 856, averageHeartRate: 145)
        )
        for _ in 0..<20 { state.effortPoints.add(bpm: 135, duration: 60, maxHR: 185) }
        for _ in 0..<30 { state.effortPoints.add(bpm: 160, duration: 60, maxHR: 185) }
        for _ in 0..<20 { state.effortPoints.add(bpm: 175, duration: 60, maxHR: 185) }
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Summary — no data") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 0, maxHeartRate: 185)
        state.isCountingDown = false
        state.summaryPhase = .presented(nil)
        return state
    }()) { HRMirrorFeature() })
}

// MARK: - Full Flow Preview

#Preview("Full Flow") {
    _HRMirrorFlowPreview()
}

private struct _HRMirrorFlowPreview: View {

    @State private var isWaiting = true
    @State private var store = Store(
        initialState: HRMirrorFeature.State(elapsedSeconds: 0, maxHeartRate: 185)
    ) { HRMirrorFeature() }

    var body: some View {
        ZStack {
            // HRMirrorView always rendered — avoids TabView flash on mount
            HRMirrorView(store: store)

            if isWaiting {
                _WaitingPreviewView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isWaiting)
        .task {
            // Phase 1: Waiting screen — 2 s
            try? await Task.sleep(for: .seconds(2))
            // Phase 2: Fade out waiting → countdown overlay visible — 2 s
            isWaiting = false
            try? await Task.sleep(for: .seconds(2))
            // Phase 3: countdown cleared (state default isCountingDown=true),
            // first HR reading lands on the live HR view
            store.send(.countdownFinished)
            store.send(.hrReceived(72))
        }
    }
}

private struct _WaitingPreviewView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text(String(localized: "Waiting for workout…"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
