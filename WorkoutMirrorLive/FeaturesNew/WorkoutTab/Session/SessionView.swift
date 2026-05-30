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

#Preview("landscape — Threshold", traits: .landscapeLeft) {
    var state = SessionFeature.State(sessionState: .session, selectedWorkout: .cross)
    state.live.currentHeartRateZone = .threshold
    state.live.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 168, activeEnergy: 520)
    state.live.currentHeartRatePercentage = 85
    state.live.sessionMaxHeartRate = 172
    return SessionView(
        store: Store(initialState: state) { SessionFeature() }
    )
}

