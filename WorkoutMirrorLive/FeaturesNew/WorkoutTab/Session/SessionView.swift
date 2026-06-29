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
                    HeartRateZoneInfoView(store: store)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: joinLiveClassSheetBinding) {
                    if let joinStore = store.scope(state: \.joinLiveClass, action: \.joinLiveClass) {
                        JoinLiveClassView(store: joinStore)
                            .presentationDetents([.medium, .large])
                    }
                }
        }
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

    /// Manual binding — `isJoinLiveClassSheetPresented` nie jest BindingState (SessionFeature
    /// nie ma BindingReducer). Get reads state; set tylko reaguje na dismiss (swipe / X),
    /// pokazywanie sheet'a inicjuje `joinLiveClassToolbarButtonTapped`.
    private var joinLiveClassSheetBinding: Binding<Bool> {
        Binding(
            get: { store.isJoinLiveClassSheetPresented },
            set: { newValue in
                if !newValue { store.send(.joinLiveClassSheetDismissed) }
            }
        )
    }

    @ViewBuilder
    private var joinLiveClassIcon: some View {
        // Single SF Symbol = native iOS 26 Liquid Glass styling w toolbarze
        // (spójność z `heart.text.clipboard` + `timer` w tej samej grupie).
        // Stan komunikujemy przez wariant fill + color + symbol effect.
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

// HR zone previews — STATIC widoki z produktowo skalibrowanymi wartościami per strefa.
// Wartości HR/avgHR/maxHR/energy zsynchronizowane z LiveSessionView.swift:358-428.
// Stopwatch hidden (isVisible=false) — w session view stopwatch ma tylko expanded
// panel (z Reset/Continue), nie always-on display. Ukrywamy → clean HR-focused view.

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

// Noop SessionClient — wszystkie streams empty (finished), wszystkie actions no-op.
// `elapsed` param: ControlsView ma TimelineView 30Hz który wywołuje
// `elapsedTimeAt(date)` co 33ms i nadpisuje `state.controls.elapsedTime`. Bez
// zwracania ustalonej wartości tutaj — timer w preview pokazuje 00:00,00.
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
        sendLifecycleEventToWatch: { _ in },
        recoverPrimarySession: { _ in }
    )
}

// Watch noop — `initializeWatchConnectivity` wisi 24h, blokując viewDidAppear
// effect przed `sessionViewStateChange(.countdown)` które nadpisałoby sessionState.
private let previewWatchClient = WatchConnectivityClient(
    initializeWatchConnectivity: {
        try? await Task.sleep(for: .seconds(86_400))
    },
    checkWatchStatus: { .unknown },
    stopWatchConnectivity: {},
    sendWorkoutEvent: { _ in },
    incomingEventStream: { AsyncStream { $0.finish() } }
)

// PersonalDataClient defensywnie — `makeCalculationForSession` używa go, ale w preview
// viewDidAppear wisi w `previewWatchClient.initializeWatchConnectivity` przed dotarciem
// tu. Override zostawiony jako safety net gdyby kolejność zmian w lifecycle.swift.
//
// UWAGA: `MaxHeartRateClient` ma internal memberwise init (mimo public struct), więc
// nie da się go zainicjalizować z poza HealthHub. Pomijamy override — z hangiem
// w viewDidAppear `makeCalculationForSession` i tak nie pójdzie do końca.
private let previewPersonalDataClient = PersonalDataClient(
    getAge: { 40 },
    getBiologicalSex: { nil },
    getHeight: { nil },
    getWeight: { _ in nil },
    getWeightForDate: { _ in nil },
    getRestingHeartRate: { _ in nil }
)

