//
//  IntervalTimerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 06/09/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Work/rest round timer of the live session (boxing rounds). Deadline-driven:
/// the reducer schedules ONE wake-up per segment boundary and the view derives
/// the countdown from `segmentEndDate` — no per-tick actions through the Store
/// (the 10 ms StopwatchFeature pattern is deliberately not repeated here).
@Reducer
struct IntervalTimerFeature {

    /// Lead-in before round 1, so the user can walk up to the bag.
    static let countdownSeconds = 3

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.roundSignal) var roundSignal

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        /// Work/rest configuration driving the rounds.
        var config: IntervalPlan

        /// True when the config came from the plan — ad-hoc editing is locked.
        let isFromPlan: Bool

        /// Machine phase; segment transitions are scheduled, never ticked.
        var phase: Phase = .idle

        /// 1-based round number while running; 0 when idle.
        var roundIndex: Int = 0

        /// Absolute end of the running segment; the view counts down to it.
        var segmentEndDate: Date?

        /// Actual start of the running segment — survives a session pause
        /// (unlike `segmentEndDate`, which is re-armed on resume), so the
        /// completed segment reports its REAL wall-clock interval.
        var segmentStartDate: Date?

        /// Remaining segment seconds frozen by a session pause.
        var pausedRemaining: TimeInterval?

        /// Ad-hoc configuration sheet (free workouts only).
        var isConfigSheetPresented: Bool = false

        /// User mute for the round signals — needed because the `.playback`
        /// session deliberately bypasses the system silent switch. Persisted.
        @Shared(.appStorage("intervalRoundSignalsMuted")) var isMuted: Bool = false

        enum Phase: Equatable {
            /// Configured, waiting for Start.
            case idle
            /// 3-second lead-in before round 1.
            case countdown
            /// Work segment of `roundIndex`.
            case work
            /// Rest segment after `roundIndex`.
            case rest
            /// All rounds done — the session itself keeps running.
            case finished
        }

        /// True while a pause can freeze a running segment.
        var isRunning: Bool {
            phase == .countdown || phase == .work || phase == .rest
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Two-way bindings (config sheet steppers, sheet presentation).
        case binding(BindingAction<State>)

        /// The scheduled wake-up at the end of the running segment.
        case segmentFinished

        /// The scheduled warning wake-up (signal only): −10 s of a work
        /// segment, or the last second of a rest segment.
        case warningFired

        /// Session pause forwarded by the parent — freezes the remaining time.
        case sessionPaused

        /// Session resume forwarded by the parent — re-arms the segment.
        case sessionResumed

        /// Facts for the parent — completed segments become workout events.
        case delegate(Delegate)

        /// Actions sent by the view.
        case view(View)

        @CasePathable
        enum Delegate {

            /// A work/rest segment finished with its REAL date interval
            /// (session pauses stretch it; skips shorten it).
            case segmentCompleted(RoundSegment)
        }

        @CasePathable
        enum View {

            /// idle → 3-second countdown → round 1.
            case startTapped

            /// Ends the running segment right now (advance without waiting).
            case skipSegmentTapped

            /// Restarts the running segment; tapped near its start (first 2 s)
            /// jumps to the previous segment — the undo of an accidental skip.
            case previousSegmentTapped

            /// Back to idle from any state (config preserved).
            case resetTapped

            /// Toggles the persisted signal mute.
            case muteTapped
        }
    }

    private nonisolated enum CancelID: Hashable, Sendable {
        case segment
        case warning
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.startTapped):
                guard state.phase == .idle else { return .none }
                state.phase = .countdown
                state.roundIndex = 0
                return arm(&state, seconds: TimeInterval(Self.countdownSeconds))

            case .view(.skipSegmentTapped):
                guard state.isRunning, state.pausedRemaining == nil else { return .none }
                return .concatenate(
                    .cancel(id: CancelID.segment),
                    .send(.segmentFinished)
                )

            case .view(.previousSegmentTapped):
                guard state.isRunning, state.pausedRemaining == nil,
                      let end = state.segmentEndDate
                else { return .none }
                let elapsed = currentSegmentSeconds(state) - end.timeIntervalSince(now)
                if elapsed >= 2 {
                    // Restart the running segment with its full duration.
                    return arm(&state, seconds: currentSegmentSeconds(state))
                }
                // Near the segment start — step back to the previous segment.
                switch state.phase {
                case .rest:
                    state.phase = .work
                    return arm(&state, seconds: TimeInterval(state.config.workSeconds))
                case .work where state.roundIndex > 1:
                    if state.config.restSeconds > 0 {
                        state.roundIndex -= 1
                        state.phase = .rest
                        return arm(&state, seconds: TimeInterval(state.config.restSeconds))
                    }
                    state.roundIndex -= 1
                    return arm(&state, seconds: TimeInterval(state.config.workSeconds))
                case .work, .countdown:
                    // Round 1 / countdown have nothing before them — restart.
                    return arm(&state, seconds: currentSegmentSeconds(state))
                case .idle, .finished:
                    return .none
                }

            case .view(.muteTapped):
                state.$isMuted.withLock { $0.toggle() }
                return .none

            case .view(.resetTapped):
                state.phase = .idle
                state.roundIndex = 0
                state.segmentEndDate = nil
                state.segmentStartDate = nil
                state.pausedRemaining = nil
                return .merge(
                    .cancel(id: CancelID.segment),
                    .cancel(id: CancelID.warning)
                )

            case .segmentFinished:
                // Close the just-finished segment BEFORE transitioning — the
                // current phase/roundIndex still describe it.
                let completed = closeSegment(&state)
                switch state.phase {
                case .countdown:
                    state.roundIndex = 1
                    state.phase = .work
                    return .merge(
                        arm(&state, seconds: TimeInterval(state.config.workSeconds)),
                        play(.workStarted, muted: state.isMuted)
                    )

                case .work:
                    guard state.roundIndex < state.config.rounds else {
                        // The last round has no trailing rest — straight to done.
                        state.phase = .finished
                        state.segmentEndDate = nil
                        return .merge(
                            .cancel(id: CancelID.segment),
                            .cancel(id: CancelID.warning),
                            play(.finished, muted: state.isMuted),
                            completed
                        )
                    }
                    guard state.config.restSeconds > 0 else {
                        state.roundIndex += 1
                        state.phase = .work
                        return .merge(
                            arm(&state, seconds: TimeInterval(state.config.workSeconds)),
                            play(.workStarted, muted: state.isMuted),
                            completed
                        )
                    }
                    state.phase = .rest
                    return .merge(
                        arm(&state, seconds: TimeInterval(state.config.restSeconds)),
                        play(.restStarted, muted: state.isMuted),
                        completed
                    )

                case .rest:
                    state.roundIndex += 1
                    state.phase = .work
                    return .merge(
                        arm(&state, seconds: TimeInterval(state.config.workSeconds)),
                        play(.workStarted, muted: state.isMuted),
                        completed
                    )

                case .idle, .finished:
                    return .none
                }

            case .warningFired:
                return play(state.phase == .rest ? .restEnding : .tenSecondsLeft, muted: state.isMuted)

            case .sessionPaused:
                guard state.isRunning, let end = state.segmentEndDate else { return .none }
                state.pausedRemaining = max(0, end.timeIntervalSince(now))
                state.segmentEndDate = nil
                return .merge(
                    .cancel(id: CancelID.segment),
                    .cancel(id: CancelID.warning)
                )

            case .sessionResumed:
                guard state.isRunning, let remaining = state.pausedRemaining else { return .none }
                state.pausedRemaining = nil
                // preservingStart — the pause belongs to the segment's real span.
                return arm(&state, seconds: remaining, preservingStart: true)

            case .delegate:
                return .none

            case .binding:
                return .none
            }
        }
    }

    // MARK: - Helpers

    /// Full duration of the segment the machine is currently in.
    private func currentSegmentSeconds(_ state: State) -> TimeInterval {
        switch state.phase {
        case .countdown: TimeInterval(Self.countdownSeconds)
        case .work:      TimeInterval(state.config.workSeconds)
        case .rest:      TimeInterval(state.config.restSeconds)
        case .idle, .finished: 0
        }
    }

    /// Emits the just-finished work/rest segment to the parent with its REAL
    /// interval. Countdown is not a segment; a restart (◀︎) or reset drops the
    /// partial fragment instead (redo semantics, not a completed round).
    private func closeSegment(_ state: inout State) -> Effect<Action> {
        guard state.phase == .work || state.phase == .rest,
              let start = state.segmentStartDate, start <= now
        else { return .none }
        let segment = RoundSegment(
            roundIndex: state.roundIndex,
            kind: state.phase == .work ? .work : .rest,
            dateInterval: DateInterval(start: start, end: now)
        )
        state.segmentStartDate = nil
        return .send(.delegate(.segmentCompleted(segment)))
    }

    /// Sets the segment deadline and schedules the boundary wake-up — plus the
    /// warning wake-up: −10 s of a work segment, last second of a rest segment.
    /// `preservingStart` keeps `segmentStartDate` (resume after a session pause).
    private func arm(_ state: inout State, seconds: TimeInterval, preservingStart: Bool = false) -> Effect<Action> {
        if !preservingStart {
            state.segmentStartDate = now
        }
        state.segmentEndDate = now.addingTimeInterval(seconds)
        let boundary = Effect<Action>.run { send in
            try await clock.sleep(for: .seconds(seconds))
            await send(.segmentFinished)
        }
        .cancellable(id: CancelID.segment, cancelInFlight: true)

        let warningLead: TimeInterval
        switch state.phase {
        case .work where seconds > 10: warningLead = 10
        case .rest where seconds > 1:  warningLead = 1
        default:
            // Also clears a stale warning left by a skipped/shortened segment.
            return .merge(boundary, .cancel(id: CancelID.warning))
        }
        let warning = Effect<Action>.run { send in
            try await clock.sleep(for: .seconds(seconds - warningLead))
            await send(.warningFired)
        }
        .cancellable(id: CancelID.warning, cancelInFlight: true)
        return .merge(boundary, warning)
    }

    private func play(_ signal: RoundSignal, muted: Bool) -> Effect<Action> {
        guard !muted else { return .none }
        return .run { [roundSignal] _ in await roundSignal.play(signal) }
    }
}
