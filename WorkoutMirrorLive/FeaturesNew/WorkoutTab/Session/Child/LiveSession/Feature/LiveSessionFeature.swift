//
//  LiveSessionFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

@Reducer
struct LiveSessionFeature {

    /// No real BLE-sensor sample for longer than this = the HR reading on screen
    /// is stale (frozen last value). Set to 35 s, not 15: at rest a healthy strap
    /// delivers only a few samples per minute, and 15 s misfired the banner
    /// between sets while the strap was fully connected. A genuine drop still
    /// surfaces the CB-reason banner; recovery is instant either way (the first
    /// fresh sample clears the flag).
    static let sensorStaleThreshold: TimeInterval = 35

    /// The Watch reports every 5 s, so three missed readings mean the shown value is no longer live.
    static let watchStaleThreshold: TimeInterval = 15

    // MARK: - Dependency
    
    @Dependency(\.sessionCalculations) var calculation
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.idleTimer) var idleTimer
    @Dependency(\.powerMode) var powerMode
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .setupMaxHeartRate(value):
                state.maxHeartRate = value
                return .none

            case let .setWorkoutType(workout):
                state.selectedWorkout = workout
                // Free boxing gets the ad-hoc rounds timer; a plan config (when
                // it arrives via setupIntervalTimer) simply replaces this default.
                if workout == .boxing, state.intervalTimer == nil {
                    state.intervalTimer = IntervalTimerFeature.State(
                        config: IntervalPlan(workSeconds: 30, restSeconds: 30, rounds: 12),
                        isFromPlan: false
                    )
                }
                return .none

            case let .setWatchConnectionLost(isLost):
                guard state.isWatchConnectionLost != isLost else { return .none }
                state.isWatchConnectionLost = isLost
                // Immediate LA push — with the link down no metrics update will arrive
                // to carry the flag, so push ContentState from the last known values.
                return .send(.liveActivity(.workout(.update(state.workoutContentState))))

            case let .setSensorDisconnectReason(reason):
                // Show/hide stays on `isSensorStale` (HealthKit freshness); this only
                // colours the banner's message. The stream emits nil on CB reconnect.
                state.lastSensorDisconnectReason = reason
                return .none

            case let .workoutMetrics(data):
                // Watch is the primary HR source. When HealthKit sends HR = 0
                // (iPhone has no wrist sensor in this mode), preserve the last
                // known value so Watch readings are not overwritten.
                let effectiveHR = data.heartRate > 0 ? data.heartRate : state.workoutMetrics.heartRate
                // Freshness gate (IOS-00100-A): in iPhone-standalone the builder
                // repeats the LAST value forever once the BLE strap drops out of
                // range — only a moved sample timestamp proves a real measurement.
                // `nil` sample date = Watch/mirroring path → every tick is fresh
                // (legacy behavior, per the two-paths invariant).
                let isFreshSample: Bool
                if let sensorSampleDate = data.heartRateSampleDate {
                    isFreshSample = sensorSampleDate != state.lastFreshSampleDate
                    if isFreshSample {
                        state.lastFreshSampleDate = sensorSampleDate
                        // Sensor is back — clear the banner right away instead of
                        // waiting for the next freshness tick. Hysteresis: only a
                        // sample measured within the staleness window counts —
                        // after a reconnect HealthKit can deliver a sample with a
                        // MOVED but still old measurement date, which used to
                        // clear the banner for one second before the tick
                        // re-raised it (banner flapping).
                        if state.isSensorStale,
                           now.timeIntervalSince(sensorSampleDate) <= Self.sensorStaleThreshold {
                            state.isSensorStale = false
                            Task { await WorkoutFileLogger.shared.log("[Connection] sensor FRESH — samples resumed") }
                        }
                    }
                } else {
                    isFreshSample = true
                    if state.isWatchPrimary, data.heartRate > 0 {
                        // The Watch sends no sample date; the arrival time is its freshness.
                        state.lastWatchReadingDate = now
                        if let isLowPowerModeEnabled = data.isLowPowerModeEnabled {
                            state.isWatchLowPowerMode = isLowPowerModeEnabled
                        }
                        if state.isSensorStale {
                            state.isSensorStale = false
                            Task { await WorkoutFileLogger.shared.log("[Connection] Watch readings RESUMED") }
                        }
                    }
                }
                if effectiveHR > 0, isFreshSample {
                    // Real sensor dates (strap) keep the gap math honest: after an
                    // outage the delta to the previous REAL sample exceeds the
                    // accumulator's 5-minute guard, so the missing stretch earns
                    // nothing. Watch path falls back to receive time, as before.
                    let sampleDate = data.heartRateSampleDate ?? now
                    // Credit effort points for the stretch since the previous
                    // sample (fed with the same effective HR the UI shows).
                    // The accumulator itself skips implausible gaps (> 5 min).
                    // A paused workout earns nothing, nor does the first sample after a resume: its gap spans the pause.
                    if let watchTotals = data.effortZoneTotals {
                        // The Watch counted every reading, also those that never reached the iPhone;
                        // what the iPhone counted before the Watch could is added on top, not replaced.
                        state.effortPoints.merge(
                            watchTotals.merging(state.locallyCountedEffort.secondsByZone, uniquingKeysWith: +)
                        )
                    } else if let previousSampleDate = state.hrBuffer.last?.date,
                              !state.isWorkoutPaused, !state.skipsNextEffortCredit {
                        let duration = sampleDate.timeIntervalSince(previousSampleDate)
                        state.effortPoints.add(bpm: Int(effectiveHR), duration: duration, maxHR: state.maxHeartRate)
                        state.locallyCountedEffort.add(bpm: Int(effectiveHR), duration: duration, maxHR: state.maxHeartRate)
                    }
                    state.skipsNextEffortCredit = false
                    state.hrBuffer.append(State.HRSample(date: sampleDate, bpm: effectiveHR))
                }
                // Keep the whole payload (incl. ride distance/speed fields for the
                // cycling tile) — only the displayed HR gets the zero-guard above.
                var updatedMetrics = data
                updatedMetrics.heartRate = effectiveHR
                state.workoutMetrics = updatedMetrics
                if effectiveHR > 0 {
                    let shownAt = now
                    Task {
                        await WorkoutFileLogger.shared.logHRIfNeeded(bpm: effectiveHR)
                        // The state above is what the screen renders, so this is the phone's "shown" moment.
                        await WorkoutFileLogger.shared.logHRTrace(stage: "ui", bpm: effectiveHR, at: shownAt)
                    }
                }
                // state.workoutMetrics updated above — the computed property assembles
                // ContentState from a single source (no manual duplication of the field list).
                let contentState = state.workoutContentState

                var effects: [Effect<Action>] = [
                    .send(.calculateHeartRateZone(Int(effectiveHR), state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(Int(effectiveHR), state.maxHeartRate)),
                    .send(.liveActivity(.workout(.update(contentState))))
                ]

                // Update session stats only when we have a real reading.
                // Skipping HealthKit zeros prevents them from skewing AVG HR;
                // skipping stale repeats (IOS-00100-A) prevents a strap outage
                // from flooding the average with one frozen value.
                if data.heartRate > 0, isFreshSample {
                    effects.append(.send(.calculateSessionHeartRateStats(Int(effectiveHR))))
                }

                if state.liveActivity.timer.isActive {
                    effects.append(.send(.liveActivity(.timer(.update(state.timerContentState)))))
                }

                return .merge(effects)
                
            case let .calculateSessionHeartRateStats(heartRate):
                return .run { send in
                    let (average, max) = await calculation.processHeartRate(heartRate)
                    await send(.updateSessionHeartRateStats(average: average, max: max))
                }
                
            case let .calculateHeartRateZone(heartRate, maxHR):
                state.currentHeartRateZone = calculation.calculateHeartRateZone(Int(heartRate), maxHR)
                return .none
                
            case let .calculateHeartRatePercentage(heartRate, maxHR):
                state.currentHeartRatePercentage = calculation.calculateHeartRatePercentage(Int(heartRate), maxHR)
                return .none
                
            case let .updateSessionHeartRateStats(average, max):
                state.sessionAverageHeartRate = average
                state.sessionMaxHeartRate = max
                return .none
                
            case .sensorFreshnessTick:
                // One clock, two sources: the strap's sample date, or the arrival time of a Watch reading.
                let lastReading = state.isWatchPrimary ? state.lastWatchReadingDate : state.lastFreshSampleDate
                let threshold = state.isWatchPrimary ? Self.watchStaleThreshold : Self.sensorStaleThreshold
                guard let lastReading else { return .none }
                let isStale = now.timeIntervalSince(lastReading) > threshold
                guard state.isSensorStale != isStale else { return .none }
                state.isSensorStale = isStale
                if isStale, state.isWatchPrimary {
                    // The first reading after the silence must not be paid for the whole gap.
                    state.skipsNextEffortCredit = true
                    state.isPhoneLowPowerMode = powerMode.isLowPowerModeEnabled()
                }
                let powerNote = state.isWatchPrimary
                    ? " (lowPower watch=\(state.isWatchLowPowerMode) phone=\(state.isPhoneLowPowerMode))"
                    : ""
                return .run { _ in
                    await WorkoutFileLogger.shared.log(
                        isStale
                            ? "[Connection] sensor STALE — no real sample for >\(Int(threshold))s\(powerNote)"
                            : "[Connection] sensor FRESH — samples resumed"
                    )
                }

            case .resetHeartRate:
                state.workoutMetrics.heartRate = 0
                return .merge(
                    .send(.calculateHeartRateZone(0, state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(0, state.maxHeartRate))
                )

                // MARK: - View Action
                
            case .view(.viewDidAppear):
                // Metrics come from SessionFeature's subscription; a second one here ran every reading twice.
                return .run { [idleTimer] _ in
                    await idleTimer.setDisabled(true)
                }

            case .view(.viewDidDisappear):
                return .run { [idleTimer] _ in
                    await idleTimer.setDisabled(false)
                }

            case let .view(.distanceTilePageChanged(page)):
                state.distanceTilePage = page
                return .none

            case .view(.planVisibilityToggled):
                state.$isPlanHidden.withLock { $0.toggle() }
                return .none

            case .view(.landscapeTimerToggleTapped):
                return .send(.toggleIntervalTimerVisibility)
                
                // MARK: - User Stopwatch Delegate

            case .userStopwatch(.delegate(.didToggleVisibility)):
                if state.userStopwatch.isVisible {
                    // Mutual exclusion: block if phase stopwatch is managing
                    if state.phaseStopwatch.isManagingPhase {
                        state.userStopwatch.isVisible = false
                        return .none
                    }
                    // The toolbar menu picks ONE tool — stopwatch hides the rounds tile.
                    state.isIntervalTimerVisible = false
                    state.phasePanel?.isTimerButtonDisabled = true
                    guard !state.liveActivity.timer.isActive else { return .none }
                    return .send(.liveActivity(.timer(.start(timerName: "Stoper", initialState: state.timerContentState))))
                } else {
                    state.phasePanel?.isTimerButtonDisabled = false
                    return .merge(
                        .send(.liveActivity(.timer(.stop))),
                        .send(.liveActivity(.workout(.start(workoutName: "Workout", initialState: state.workoutContentState))))
                    )
                }

            case .userStopwatch(.delegate(.didStart)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case .userStopwatch(.delegate(.didStop)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case .userStopwatch(.delegate(.didReset)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case let .liveActivity(.timer(.activityUpdated(newState))):
                if newState.isRunning && !state.userStopwatch.isRunning {
                    return .send(.userStopwatch(.view(.start)))
                } else if !newState.isRunning && state.userStopwatch.isRunning {
                    return .send(.userStopwatch(.view(.stop)))
                }
                return .none

            case .liveActivity(.timer(.activityStopped)):
                return .merge(
                    .send(.userStopwatch(.view(.stop))),
                    .send(.userStopwatch(.view(.setVisibility(false))))
                )

            case .userStopwatch:
                return .none

                // MARK: - Phase Stopwatch Delegate

            case .phaseStopwatch(.delegate(.returnToPhaseTimerRequested)):
                guard state.phaseStopwatch.isManagingPhase else { return .none }
                var effects: [Effect<Action>] = [
                    .send(.phaseStopwatch(.view(.stop))),
                    .send(.phaseStopwatch(.view(.setVisibility(false))))
                ]
                effects += syncPhaseStopwatchToPhasePanel(state: &state)
                return .merge(effects)

            case .phaseStopwatch:
                return .none

            case .liveActivity:
                return .none

                // MARK: - Phase Panel

            case let .setupPhasePanel(phases):
                state.phasePanel = phases.isEmpty ? nil : PhasePanelFeature.State(phases: phases)
                return .none

                // MARK: - Interval Timer

            case let .setupIntervalTimer(plan):
                if let plan {
                    state.intervalTimer = IntervalTimerFeature.State(config: plan, isFromPlan: true)
                }
                // nil = the plan has no interval WOD; a free-boxing default set
                // by setWorkoutType stays untouched.
                return .none

            case let .setWorkoutPaused(isPaused):
                if state.isWorkoutPaused, !isPaused {
                    state.skipsNextEffortCredit = true
                }
                state.isWorkoutPaused = isPaused
                guard state.intervalTimer != nil else { return .none }
                return .send(.intervalTimer(isPaused ? .sessionPaused : .sessionResumed))

            case .toggleIntervalTimerVisibility:
                guard state.intervalTimer != nil else { return .none }
                state.isIntervalTimerVisible.toggle()
                // Exclusive with the stopwatch — the toolbar menu picks ONE tool.
                if state.isIntervalTimerVisible, state.userStopwatch.isVisible {
                    return .send(.userStopwatch(.view(.setVisibility(false))))
                }
                return .none

            case .intervalTimer:
                return .none

            case let .phasePanel(.delegate(.timerManagementRequested(elapsed))):
                // Mutual exclusion: block if user stopwatch is already visible
                guard !state.userStopwatch.isVisible else { return .none }
                let wasRunning = state.phasePanel?.timerRunning ?? false
                state.phasePanel?.timerRunning = false
                state.phaseStopwatch.isManagingPhase = true
                state.phaseStopwatch.time = TimeInterval(elapsed)
                var effects: [Effect<Action>] = [
                    .cancel(id: PhasePanelFeatureCancelID.timer),
                    .send(.phaseStopwatch(.view(.setVisibility(true))))
                ]
                if wasRunning {
                    effects.append(.send(.phaseStopwatch(.view(.start))))
                }
                return .merge(effects)

            case .phasePanel:
                return .none
            }
        }
        Scope(state: \.liveActivity, action: \.liveActivity) {
            LiveActivityFeature()
        }
        Scope(state: \.userStopwatch, action: \.userStopwatch) {
            StopwatchFeature(id: StopwatchID.user)
        }
        Scope(state: \.phaseStopwatch, action: \.phaseStopwatch) {
            StopwatchFeature(id: StopwatchID.phase)
        }
        .ifLet(\.phasePanel, action: \.phasePanel) {
            PhasePanelFeature()
        }
        .ifLet(\.intervalTimer, action: \.intervalTimer) {
            IntervalTimerFeature()
        }
    }

    // MARK: - Helpers

    /// Syncs elapsed time and running state from phaseStopwatch back to the phase panel.
    /// Clears `isManagingPhase`. Returns any additional phase-panel effects needed.
    private func syncPhaseStopwatchToPhasePanel(state: inout State) -> [Effect<Action>] {
        let syncedElapsed = Int(state.phaseStopwatch.time)
        let wasRunning = state.phaseStopwatch.isRunning
        state.phasePanel?.elapsedSeconds = syncedElapsed
        state.phasePanel?.timerRunning = wasRunning
        state.phaseStopwatch.isManagingPhase = false
        guard wasRunning else { return [] }
        return [.send(.phasePanel(.timerTick))]
    }

}


