//
//  WorkoutSessionView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutSessionFeature.self)
struct WorkoutSessionView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutSessionFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .ignoresSafeArea()
            .navigationTitle(store.workoutSessionState.title)
            .navigationBarHidden(store.workoutSessionState == .countdown ? true : false)
    }
    
    @ViewBuilder
    private var rootView: some View {
        switch store.workoutSessionState {
        case .start:
            startView
        case .countdown:
            countdownView
        case .session:
            sessionView
        case .summary:
            summaryView
        }
    }
    
    @ViewBuilder
    private var startView: some View {
        if store.selectedWorkout == nil {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("Nie wybrano treningu")
                    .font(.title2)
                    .bold()
//                Button("Wróć") {
//                    send(.dismiss)
//                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            LoadingView(message: "Rozpoczynam odliczanie...") {
                send(.changeViewState(.countdown))
            }
        }
    }
    
    @ViewBuilder
    private var countdownView: some View {
        CountDownView(store: store.scope(
            state: \.countDown,
            action: \.countDown)
        )
        .padding()
    }
    
    private var sessionView: some View {
        WorkoutMirroringView(store: store.scope(
            state: \.mirroring,
            action: \.mirroring)
        )
    }
    
    private var summaryView: some View {
        Text("summary")
    }
    
}
