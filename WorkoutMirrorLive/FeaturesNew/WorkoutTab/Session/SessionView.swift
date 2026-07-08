//
//  SessionView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SessionFeature.self)
struct SessionView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SessionFeature>
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            rootView
                .ignoresSafeArea(.container, edges: .bottom)
                .navigationTitle(store.sessionState.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarTitleDisplayMode(.inline)
                .navigationBarHidden(
                    isLandscape
                    || store.sessionState == .countdown
                    || store.sessionState == .waitingForWatch
                )
                .onAppear {
                    send(.viewDidAppear)
                }
                .toolbar {
                    if !isLandscape { toolbarButtons }
                }
                .sheet(item: $store.scope(state: \.destination?.openHeartRateZoneInfo,
                                          action: \.destination.openHeartRateZoneInfo)) { store in
                    NavigationStack {
                        HeartRateZoneInfoView(store: store)
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: joinLiveClassSheetBinding) {
                    if let joinStore = store.scope(state: \.joinLiveClass, action: \.joinLiveClass) {
                        JoinLiveClassView(store: joinStore)
                            .presentationDetents([.medium, .large])
                    }
                }
                .alert($store.scope(state: \.connectionLostAlert, action: \.connectionLostAlert))
                .safeAreaInset(edge: .top) {
                    if store.isWatchConnectionLost && store.sessionState == .session {
                        connectionLostBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: store.isWatchConnectionLost)
        }
    }

    // MARK: - Connection Lost Banner (IOS-00098-G)

    /// Shown while the HealthKit mirroring link is down. The workout keeps running
    /// on the Watch (its own sensors, its own storage) — only live preview and remote
    /// control are unavailable until the system reconnects.
    private var connectionLostBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "applewatch.slash")
                .foregroundStyle(.orange)
            Text(String(localized: "Utracono połączenie z Watchem — trening trwa dalej"))
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }


    @ViewBuilder
    private var rootView: some View {
        switch store.sessionState {
        case .waitingForWatch, .countdown:
            // Dual-mode CountDownView — `phase` (set by SessionFeature) drives whether
            // we render the gray waiting ring or the green 3-2-1 progress ring.
            countdownView
        case .session:
            sessionView
        case .summary:
            summaryView
        case .finishedOnWatch:
            // Transient teardown phase — the session dismisses itself (SessionPhase),
            // the Watch shows the summary, the badge in History leads to the results.
            ProgressView()
        }
    }
    
    @ViewBuilder
    private var countdownView: some View {
        CountDownView(store: store.scope(
            state: \.countDown,
            action: \.countDown)
        )
    }
    
    @ViewBuilder
    private var sessionView: some View {
        LiveSessionView(store: store.scope(
            state: \.live,
            action: \.live)
        )
        .allowsHitTesting(!store.controls.isLocked)
        .safeAreaInset(edge: .bottom) {
            if !isLandscape { controlsView }
        }
        //.sheet(isPresented: $showPanel) {
        //    SessionControlsView()
        //        .presentationDetents([.height(120), .medium, .large])
        //        .presentationDragIndicator(.visible)
        //}
        
    }
    
    @ViewBuilder
    private var controlsView: some View {
        ControlsView(store: store.scope(
            state: \.controls,
            action: \.controls)
        )
    }
    
    @ViewBuilder
    private var summaryView: some View {
        SummaryView(store: store.scope(
            state: \.summary,
            action: \.summary)
        )
    }

    
    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        if store.sessionState != .summary {
            ToolbarItem(placement: .topBarLeading) {
                heartRateZoneButton
            }
            ToolbarItem(placement: .topBarLeading) {
                joinLiveClassButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                timerButton
            }
        }
    }

    private var heartRateZoneButton: some View {
        Button {
            send(.heartRateZoneButtonTapped)
        } label: {
            Image(systemName: "heart.text.clipboard")
        }
        .disabledWithOpacity(store.controls.isLocked)
    }

    private var joinLiveClassButton: some View {
        Button {
            send(.joinLiveClassToolbarButtonTapped)
        } label: {
            joinLiveClassIcon
        }
        .disabledWithOpacity(store.controls.isLocked)
    }

    /// Manual binding — `isJoinLiveClassSheetPresented` is not BindingState (SessionFeature
    /// has no BindingReducer). Get reads state; set only reacts to dismiss (swipe / X),
    /// showing the sheet is initiated by `joinLiveClassToolbarButtonTapped`.
    private var joinLiveClassSheetBinding: Binding<Bool> {
        Binding(
            get: { store.isJoinLiveClassSheetPresented },
            set: { newValue in
                if !newValue { send(.joinLiveClassSheetDismissed) }
            }
        )
    }

    @ViewBuilder
    private var joinLiveClassIcon: some View {
        // Single SF Symbol = native iOS 26 Liquid Glass styling in the toolbar
        // (consistency with `heart.text.clipboard` + `timer` in the same group).
        // State is communicated via the fill variant + color + symbol effect.
        let phase = store.joinLiveClass?.phase
        let iconName = (phase == .searching || phase == .connected)
            ? "person.3.sequence.fill"
            : "person.3"
        let tint: Color = phase == .connected ? .green : .primary

        Image(systemName: iconName)
            .foregroundStyle(tint)
            .symbolEffect(.variableColor.iterative, isActive: phase == .searching)
    }

    private var timerButton: some View {
        Button {
            send(.timerButtonTapped)
        } label: {
            Image(systemName: "timer")
        }
        .tint(store.live.userStopwatch.isVisible ? .orange : nil)
        .disabledWithOpacity(store.controls.isLocked || store.live.phaseStopwatch.isManagingPhase)
    }

    private var xMarkImage: some View {
        Image(systemName: "xmark")
    }

}

// MARK: - Previews

import HealthHub
import HealthKit
import SharedModels

#Preview("session") {
    NavigationStack {
        SessionView(
            store: Store(initialState: SessionFeature.State(
                sessionState: .session,
                selectedWorkout: .cross),
                         reducer: { SessionFeature() }
            )
        )
    }
}

#Preview("countdown") {
    NavigationStack {
        SessionView(
            store: Store(initialState: SessionFeature.State(
                sessionState: .countdown,
                selectedWorkout: .cross),
                         reducer: { SessionFeature() }
            )
        )
    }
}


#Preview("connection lost — banner") {
    NavigationStack {
        SessionView(
            store: Store(initialState: {
                var state = SessionFeature.State(
                    sessionState: .session,
                    selectedWorkout: .cross)
                state.workoutMode = .watchPrimary
                state.isWatchConnectionLost = true
                return state
            }(), reducer: { SessionFeature() })
        )
    }
}

#Preview("connection lost — End alert") {
    NavigationStack {
        SessionView(
            store: Store(initialState: {
                var state = SessionFeature.State(
                    sessionState: .session,
                    selectedWorkout: .cross)
                state.workoutMode = .watchPrimary
                state.isWatchConnectionLost = true
                state.connectionLostAlert = .connectionLost
                return state
            }(), reducer: { SessionFeature() })
        )
    }
}

// HR zone previews — STATIC views with product-calibrated values per zone.
// HR/avgHR/maxHR/energy values synchronized with LiveSessionView.swift:358-428.
// Stopwatch hidden (isVisible=false) — in the session view the stopwatch has only the expanded
// panel (with Reset/Continue), not an always-on display. Hiding it → clean HR-focused view.

#Preview("HR — resting", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .resting, bpm: 72, percentage: 38, avgHR: 70, maxHR: 75, energy: 0, elapsed: 135.42
    )))
}

#Preview("HR — recovery", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .recovery, bpm: 108, percentage: 55, avgHR: 102, maxHR: 112, energy: 85, elapsed: 453.84
    )))
}

#Preview("HR — fatBurning", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .fatBurning, bpm: 126, percentage: 65, avgHR: 118, maxHR: 130, energy: 210, elapsed: 802.67
    )))
}

#Preview("HR — aerobic", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .aerobic, bpm: 148, percentage: 75, avgHR: 140, maxHR: 155, energy: 380, elapsed: 1188.91
    )))
}

#Preview("HR — threshold", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .threshold, bpm: 168, percentage: 85, avgHR: 155, maxHR: 172, energy: 520, elapsed: 1575.33
    )))
}

#Preview("HR — anaerobic", traits: .landscapeLeft) {
    SessionView(store: previewStore(state: previewState(
        zone: .anaerobic, bpm: 185, percentage: 95, avgHR: 170, maxHR: 188, energy: 680, elapsed: 2049.78
    )))
}

// MARK: - Preview Helpers

private func previewState(
    zone: HeartRateZone,
    bpm: Double,
    percentage: Int,
    avgHR: Int,
    maxHR: Int,
    energy: Double,
    elapsed: TimeInterval
) -> SessionFeature.State {
    var state = SessionFeature.State(sessionState: .session, selectedWorkout: .cross)
    state.live.currentHeartRateZone = zone
    state.live.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: bpm, activeEnergy: energy)
    state.live.currentHeartRatePercentage = percentage
    state.live.sessionAverageHeartRate = avgHR
    state.live.sessionMaxHeartRate = maxHR
    state.live.maxHeartRate = 188
    state.controls.elapsedTime = elapsed
    state.controls.sessionState = .running
    return state
}

private func previewStore(state: SessionFeature.State) -> StoreOf<SessionFeature> {
    Store(initialState: state) {
        SessionFeature()
            .dependency(\.sessionClient, previewSessionClient(elapsed: state.controls.elapsedTime))
            .dependency(\.watchConnectivityClient, previewWatchClient)
            .dependency(\.personalDataClient, previewPersonalDataClient)
            .dependency(\.idleTimer, IdleTimerClient(setDisabled: { _ in }))
    }
}

// Noop SessionClient — all streams empty (finished), all actions no-op.
// `elapsed` param: ControlsView has a 30Hz TimelineView which calls
// `elapsedTimeAt(date)` every 33ms and overwrites `state.controls.elapsedTime`. Without
// returning a fixed value here — the timer in the preview shows 00:00,00.
private func previewSessionClient(elapsed: TimeInterval) -> SessionClient {
    SessionClient(
        selectedWorkout: { _ in },
        workoutMetricsStream: { AsyncStream { $0.finish() } },
        workoutSessionStateStream: { AsyncStream { $0.finish() } },
        elapsedTimeAt: { _ in elapsed },
        togglePause: {},
        getWorkoutSummary: {
            WorkoutSummary(workout: nil, metrics: WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0))
        },
        endWorkout: {},
        startWatchWorkout: { _ in },
        deleteWorkout: { _ in },
        setWorkoutMode: { _ in },
        incrementElapsed: { 0 },
        resetElapsed: {},
        markResumeElapsed: {},
        startWorkout: {},
        mirroredSessionStartedStream: { AsyncStream { $0.finish() } },
        watchConnectionStatusStream: { AsyncStream { $0.finish() } },
        sendLifecycleEventToWatch: { _ in true },
        recoverPrimarySession: { _ in }
    )
}

// Watch noop — `initializeWatchConnectivity` hangs for 24h, blocking the viewDidAppear
// effect before `sessionViewStateChange(.countdown)` which would overwrite sessionState.
private let previewWatchClient = WatchConnectivityClient(
    initializeWatchConnectivity: {
        try? await Task.sleep(for: .seconds(86_400))
    },
    checkWatchStatus: { .unknown },
    stopWatchConnectivity: {},
    sendWorkoutEvent: { _ in },
    incomingEventStream: { AsyncStream { $0.finish() } }
)

// PersonalDataClient defensively — `makeCalculationForSession` uses it, but in the preview
// viewDidAppear hangs in `previewWatchClient.initializeWatchConnectivity` before reaching
// here. Override kept as a safety net in case the order of changes in lifecycle.swift shifts.
//
// NOTE: `MaxHeartRateClient` has an internal memberwise init (despite being a public struct), so
// it cannot be initialized from outside HealthHub. We skip the override — with the hang
// in viewDidAppear, `makeCalculationForSession` will not run to completion anyway.
private let previewPersonalDataClient = PersonalDataClient(
    getAge: { 40 },
    getBiologicalSex: { nil },
    getHeight: { nil },
    getWeight: { _ in nil },
    getWeightForDate: { _ in nil },
    getRestingHeartRate: { _ in nil }
)

