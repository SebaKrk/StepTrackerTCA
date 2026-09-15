//
//  IntervalTimerLandscapeView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/09/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Landscape "gym clock" card of the boxing-rounds timer — the phone leans
/// against a wall and is read from across the room, so the digits dominate.
/// Same glass material as the landscape metrics card; colors, labels, and
/// countdown math come from `IntervalTimerFeature+Display` (shared with the
/// portrait tile).
@ViewAction(for: IntervalTimerFeature.self)
struct IntervalTimerLandscapeView: View {

    let store: StoreOf<IntervalTimerFeature>

    /// Parent-owned zones ⇄ intervals switch — the card only renders the button.
    let onSwitchToZones: () -> Void

    // The parent shows this card only while rounds run (`isRunning`) — idle
    // and finished never render here; start/config live on the portrait tile.
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            card {
                VStack(spacing: 6) {
                    runningHeader
                    Spacer(minLength: 0)
                    countdownText(at: context.date)
                    Spacer(minLength: 0)
                    segmentProgressBar(at: context.date)
                    roundDots
                }
            }
            .overlay(stateBorder(at: context.date))
        }
    }

    // MARK: - Structure

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Implementation (running)

    private var runningHeader: some View {
        HStack(spacing: 10) {
            statePill
            muteButton
            Spacer(minLength: 6)
            if store.phase != .countdown {
                roundCounterPill
            }
            if !store.isPaused {
                navButtons
            }
            switchToZonesButton
        }
    }

    private var statePill: some View {
        Text(store.segmentTitle)
            .font(.subheadline.weight(.heavy))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            .background(store.accent.opacity(0.85), in: .capsule)
    }

    private var roundCounterPill: some View {
        (
            Text("\(store.roundIndex)")
            + Text(verbatim: "/\(store.config.rounds)").foregroundStyle(.secondary)
        )
        .font(.subheadline.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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

    /// Persisted signal mute — the `.playback` bells bypass the system silent
    /// switch, so the app must offer its own switch.
    private var muteButton: some View {
        Button {
            send(.muteTapped)
        } label: {
            Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(store.isMuted ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .frame(width: 32, height: 32)
                .background(Color.primary.opacity(0.08), in: .circle)
                .contentShape(Circle().inset(by: -4))
        }
        .buttonStyle(.plain)
    }

    /// Back to the heart-rate zones card (LiveSession-level state).
    private var switchToZonesButton: some View {
        navButton(systemImage: "heart.fill") {
            onSwitchToZones()
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
        Text(store.state.remainingLabel(at: renderDate))
            .font(.system(size: 130, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .opacity(store.isPaused ? 0.7 : 1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
            .contentTransition(.numericText(countsDown: true))
    }

    private func segmentProgressBar(at renderDate: Date) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(store.accent.opacity(0.85))
                    .frame(width: proxy.size.width * store.state.segmentFraction(at: renderDate))
            }
        }
        .frame(height: 10)
    }

    /// One dot per round; above 15 the counter pill alone carries the progress.
    @ViewBuilder
    private var roundDots: some View {
        if store.config.rounds <= 15 {
            HStack(spacing: 6) {
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
            .fill(isPast ? AnyShapeStyle(store.accent) : isCurrent ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.primary.opacity(0.18)))
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .strokeBorder(store.accent.opacity(isCurrent ? 0.6 : 0), lineWidth: 2)
                    .padding(-3)
            )
    }

    /// Accent ring inside the card — concentric with the glass: 24 − 7 = 17.
    private func stateBorder(at renderDate: Date) -> some View {
        let isFinalTen = store.phase == .work && !store.isPaused && store.state.remainingSeconds(at: renderDate) <= 10
        return RoundedRectangle(cornerRadius: 17, style: .continuous)
            .strokeBorder(store.accent.opacity(isFinalTen ? 0.85 : 0.55), lineWidth: isFinalTen ? 2.5 : 1.5)
            .shadow(color: store.accent.opacity(isFinalTen ? 0.45 : 0), radius: 12)
            .padding(7)
            .allowsHitTesting(false)
    }

}

// MARK: - Previews

#Preview("Landscape — running", traits: .landscapeLeft) {
    var state = IntervalTimerFeature.State(
        config: IntervalPlan(workSeconds: 30, restSeconds: 30, rounds: 12),
        isFromPlan: true
    )
    state.phase = .work
    state.roundIndex = 2
    state.segmentEndDate = Date().addingTimeInterval(23)
    return IntervalTimerLandscapeView(
        store: Store(initialState: state) {
            IntervalTimerFeature()
        },
        onSwitchToZones: {}
    )
    .padding()
    .background(
        LinearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottom)
    )
    .preferredColorScheme(.dark)
}
