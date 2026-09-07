//
//  IntervalTimerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 06/09/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Boxing-rounds tile of the live session. Same material as every other card
/// on this screen (`styledGroupBox`) — the segment state rides on an accent
/// (pill, 84 pt glowing digits, bar, dots), not on a full-surface fill.
/// Accents reuse the system palette of `HeartRateZone` (green work / red rest,
/// the traffic-light convention). Rendering ticks live in TimelineView — the
/// Store only sees segment boundaries.
@ViewAction(for: IntervalTimerFeature.self)
struct IntervalTimerView: View {
    @Bindable var store: StoreOf<IntervalTimerFeature>

    var body: some View {
        content
            .sheet(isPresented: $store.isConfigSheetPresented) {
                configSheet
            }
    }

    // MARK: - Structure

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle:
            idleCard
        case .countdown, .work, .rest:
            runningCard
        case .finished:
            finishedCard
        }
    }

    private var idleCard: some View {
        GroupBox {
            HStack(spacing: 12) {
                idleSummary
                Spacer(minLength: 8)
                if !store.isFromPlan {
                    configButton
                }
                startButton
            }
        }
        .styledGroupBox()
    }

    private var runningCard: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            GroupBox {
                VStack(spacing: 8) {
                    runningHeader
                    countdownText(at: context.date)
                    segmentProgressBar(at: context.date)
                    roundDots
                }
            }
            .styledGroupBox()
            .overlay(stateBorder(at: context.date))
        }
    }

    private var finishedCard: some View {
        GroupBox {
            HStack(spacing: 12) {
                finishedCheck
                finishedTitles
                Spacer(minLength: 8)
                resetButton
            }
        }
        .styledGroupBox()
    }

    // MARK: - Implementation (idle)

    private var idleSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Rounds")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(secondsLabel(store.config.workSeconds)) / \(secondsLabel(store.config.restSeconds)) × \(store.config.rounds)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var startButton: some View {
        Button {
            send(.startTapped)
        } label: {
            Label(String(localized: "Start"), systemImage: "play.fill")
                .font(.subheadline.weight(.bold))
        }
        .buttonStyle(.borderedProminent)
        // App-wide AccentColor asset is empty — prominent needs an explicit tint.
        .tint(Self.workAccent)
    }

    private var configButton: some View {
        Button {
            store.isConfigSheetPresented = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(Color.primary.opacity(0.08), in: .rect(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Implementation (running)

    private var runningHeader: some View {
        HStack(spacing: 10) {
            statePill
            Spacer(minLength: 6)
            if store.phase != .countdown {
                roundCounterPill
            }
            if !isPaused {
                navButtons
            }
        }
    }

    private var statePill: some View {
        Text(segmentTitle)
            .font(.caption.weight(.heavy))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 4)
            .background(accent.opacity(0.85), in: .capsule)
            .opacity(isPaused && !reduceMotion ? 0.75 : 1)
    }

    private var roundCounterPill: some View {
        (
            Text("\(store.roundIndex)")
            + Text(verbatim: "/\(store.config.rounds)").foregroundStyle(.secondary)
        )
        .font(.footnote.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.08), in: .capsule)
    }

    private var navButtons: some View {
        HStack(spacing: 8) {
            navButton(systemImage: "backward.end.fill") {
                send(.previousSegmentTapped)
            }
            navButton(systemImage: "forward.end.fill") {
                send(.skipSegmentTapped)
            }
        }
    }

    private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Color.primary.opacity(0.08), in: .circle)
                .contentShape(Circle().inset(by: -4))
        }
        .buttonStyle(.plain)
    }

    private func countdownText(at renderDate: Date) -> some View {
        // White like every big number on this screen (AVG/MAX HR, HR %) — the
        // zone palette carries the state in the pill/bar/dots, never full-size.
        Text(remainingLabel(at: renderDate))
            .font(.system(size: 84, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .opacity(isPaused ? 0.7 : 1)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .contentTransition(.numericText(countsDown: true))
    }

    private func segmentProgressBar(at renderDate: Date) -> some View {
        // Slightly taller than a hairline — with the digits white, the bar and
        // the pill are the distance-readable state carriers.
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(accent.opacity(0.85))
                    .frame(width: proxy.size.width * segmentFraction(at: renderDate))
            }
        }
        .frame(height: 8)
    }

    /// Whole-workout progress: one dot per round. Above 15 rounds the dots
    /// would crowd — the counter pill alone carries the progress then.
    @ViewBuilder
    private var roundDots: some View {
        if store.config.rounds <= 15 {
            HStack(spacing: 5) {
                ForEach(1...store.config.rounds, id: \.self) { round in
                    roundDot(round)
                }
            }
        }
    }

    private func roundDot(_ round: Int) -> some View {
        let isPast = round < store.roundIndex
        let isCurrent = round == store.roundIndex && store.phase != .countdown
        return Circle()
            .fill(isPast ? AnyShapeStyle(accent) : isCurrent ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.primary.opacity(0.18)))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .strokeBorder(accent.opacity(isCurrent ? 0.6 : 0), lineWidth: 2)
                    .padding(-3)
            )
    }

    /// Accent ring INSIDE the card (inset from the GroupBox edge) — the
    /// strongest at-a-glance carrier of "box vs rest". Final 10 s of work
    /// thicken it and add a glow (the visual twin of the −10 s clap signal).
    private func stateBorder(at renderDate: Date) -> some View {
        let isFinalTen = store.phase == .work && !isPaused && remainingSeconds(at: renderDate) <= 10
        // Concentric with the styledGroupBox card: 24 (continuous) − 7 inset = 17.
        return RoundedRectangle(cornerRadius: 17, style: .continuous)
            .strokeBorder(accent.opacity(isFinalTen ? 0.85 : 0.55), lineWidth: isFinalTen ? 2.5 : 1.5)
            .shadow(color: accent.opacity(isFinalTen ? 0.45 : 0), radius: 12)
            .padding(7)
            .allowsHitTesting(false)
    }

    // MARK: - Implementation (finished)

    private var finishedCheck: some View {
        Image(systemName: "checkmark")
            .font(.title3.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Self.workAccent, in: .circle)
    }

    private var finishedTitles: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Rounds done: \(store.config.rounds)")
                .font(.headline)
                .foregroundStyle(.primary)
            Text(verbatim: finishedSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var finishedSummary: String {
        let workTotal = store.config.rounds * store.config.workSeconds
        let restTotal = max(0, store.config.rounds - 1) * store.config.restSeconds
        return "\(minutesLabel(workTotal)) · \(minutesLabel(restTotal))"
    }

    private var resetButton: some View {
        Button {
            send(.resetTapped)
        } label: {
            Text("Reset")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Implementation (config sheet)

    private var configSheet: some View {
        NavigationStack {
            Form {
                Stepper(
                    "\(String(localized: "Work")): \(secondsLabel(store.config.workSeconds))",
                    value: workBinding,
                    in: 10...600,
                    step: 5
                )
                Stepper(
                    "\(String(localized: "Rest")): \(secondsLabel(store.config.restSeconds))",
                    value: restBinding,
                    in: 0...600,
                    step: 5
                )
                Stepper(
                    "\(String(localized: "Rounds")): \(store.config.rounds)",
                    value: roundsBinding,
                    in: 1...99,
                    step: 1
                )
            }
            .navigationTitle(String(localized: "Rounds"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var workBinding: Binding<Int> {
        Binding(
            get: { store.config.workSeconds },
            set: { store.config = IntervalPlan(workSeconds: $0, restSeconds: store.config.restSeconds, rounds: store.config.rounds) }
        )
    }

    private var restBinding: Binding<Int> {
        Binding(
            get: { store.config.restSeconds },
            set: { store.config = IntervalPlan(workSeconds: store.config.workSeconds, restSeconds: $0, rounds: store.config.rounds) }
        )
    }

    private var roundsBinding: Binding<Int> {
        Binding(
            get: { store.config.rounds },
            set: { store.config = IntervalPlan(workSeconds: store.config.workSeconds, restSeconds: store.config.restSeconds, rounds: $0) }
        )
    }

    // MARK: - Implementation (accents & formatting)

    private var isPaused: Bool { store.pausedRemaining != nil }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var segmentTitle: String {
        if isPaused { return String(localized: "Paused") }
        switch store.phase {
        case .countdown: return String(localized: "Get ready")
        // Deliberately "Box", not "Work" — the tile talks gym language;
        // the plan editor keeps the generic Work/Rest wording.
        case .work:      return String(localized: "Box")
        case .rest:      return String(localized: "Rest")
        case .idle, .finished: return ""
        }
    }

    /// Traffic-light semantics on the HeartRateZone system palette:
    /// green = fight, red = stop and recover.
    private var accent: Color {
        if isPaused { return Self.pausedAccent }
        switch store.phase {
        case .work:      return Self.workAccent
        case .rest:      return Self.restAccent
        case .countdown: return Self.readyAccent
        case .idle, .finished: return Self.workAccent
        }
    }

    private static let workAccent = Color.green      // HeartRateZone.fatBurning
    private static let restAccent = Color.red        // HeartRateZone.anaerobic
    private static let readyAccent = Color.yellow    // HeartRateZone.aerobic
    private static let pausedAccent = Color.gray     // HeartRateZone.resting

    /// Frozen remaining seconds during a pause, live countdown otherwise.
    private func remainingSeconds(at renderDate: Date) -> Int {
        if let frozen = store.pausedRemaining {
            return Int(frozen.rounded(.up))
        }
        guard let end = store.segmentEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSince(renderDate).rounded(.up)))
    }

    private func remainingLabel(at renderDate: Date) -> String {
        let seconds = remainingSeconds(at: renderDate)
        return seconds >= 60
            ? String(format: "%d:%02d", seconds / 60, seconds % 60)
            : "\(seconds)"
    }

    private func segmentFraction(at renderDate: Date) -> CGFloat {
        let total: Int
        switch store.phase {
        case .work:      total = store.config.workSeconds
        case .rest:      total = store.config.restSeconds
        case .countdown: total = IntervalTimerFeature.countdownSeconds
        case .idle, .finished: return 0
        }
        guard total > 0 else { return 0 }
        return CGFloat(remainingSeconds(at: renderDate)) / CGFloat(total)
    }

    private func secondsLabel(_ seconds: Int) -> String {
        seconds < 60
            ? "\(seconds) s"
            : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func minutesLabel(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Previews

#Preview("Idle — free workout") {
    IntervalTimerView(
        store: Store(
            initialState: IntervalTimerFeature.State(
                config: IntervalPlan(workSeconds: 180, restSeconds: 60, rounds: 10),
                isFromPlan: false
            )
        ) {
            IntervalTimerFeature()
        }
    )
    .padding()
    .background(
        LinearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottom)
    )
}

#Preview("Running — interactive") {
    IntervalTimerView(
        store: Store(
            initialState: IntervalTimerFeature.State(
                config: IntervalPlan(workSeconds: 15, restSeconds: 5, rounds: 5),
                isFromPlan: true
            )
        ) {
            IntervalTimerFeature()
        }
    )
    .padding()
    .background(
        LinearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottom)
    )
}
