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
                .navigationBarHidden(isLandscape || store.sessionState == .countdown)
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
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        switch store.sessionState {
        case .countdown:
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
        .frame(width: 200, height: 200, alignment: .center)
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
                Button {
                    send(.heartRateZoneButtonTapped)
                } label: {
                    Image(systemName: "heart.text.clipboard")
                }
                .disabledWithOpacity(store.controls.isLocked)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.timerButtonTapped)
                } label: {
                    Image(systemName: "timer")
                }
                .tint(store.live.userStopwatch.isVisible ? .orange : nil)
                .disabledWithOpacity(store.controls.isLocked || store.live.phaseStopwatch.isManagingPhase)
            }
        }
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

