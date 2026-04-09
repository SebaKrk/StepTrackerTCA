//
//  AppViewAW.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SwiftUI

/// Root view of the WorkoutMirror Watch App.
///
/// Displays a waiting state when no workout is active on the paired iPhone,
/// and presents `HRMirrorView` full-screen when a workout session starts.
@ViewAction(for: AppFeatureAW.self)
struct AppViewAW: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<AppFeatureAW>

    // MARK: - View

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            waitingView
        }
        .fullScreenCover(
            item: $store.scope(state: \.hrMirror, action: \.hrMirror)
        ) { hrMirrorStore in
            HRMirrorView(store: hrMirrorStore)
                .onDisappear {
                    print("⌚ [DEBUG] HRMirrorView disappeared — fullScreenCover dismissed")
                }
        }
        .onChange(of: store.hrMirror == nil) { _, isNil in
            if isNil {
                print("⌚ [DEBUG] hrMirror state became nil — cover will dismiss")
            }
        }
        .onAppear {
            send(.onAppear)
        }
    }

    // MARK: - Subviews

    private var waitingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text(String(localized: "Waiting for workout…"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    AppViewAW(store: Store(initialState: AppFeatureAW.State()) {
        AppFeatureAW()
    })
}
