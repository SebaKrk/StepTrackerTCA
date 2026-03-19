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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
//                .ignoresSafeArea()
//                .ignoresSafeArea(.keyboard, edges: [.top])
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(store.sessionState.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarTitleDisplayMode(.inline)
                .navigationBarHidden(store.sessionState == .countdown ? true : false)
                .onAppear {
                    send(.viewDidAppear)
                }
                .toolbar {
                    toolbarButtons
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
        .safeAreaInset(edge: .bottom) {
            controlsView
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
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.timerButtonTapped)
                } label: {
                    Image(systemName: "timer")
                }
                .disabledWithOpacity(store.live.phaseStopwatch.isManagingPhase)
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

