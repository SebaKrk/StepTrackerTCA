//
//  SummaryView+LoadingStates.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//
//  Loading state views (saving / loading / failed) — non-success view states.
//  Wydzielony z monolithic SummaryView.swift w IOS-00096-D.

import ComposableArchitecture
import SwiftUI

extension SummaryView {

    // MARK: - Saving

    var savingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "Saving workout..."))
                .font(.headline)
            Text(String(localized: "Waiting for Apple Watch"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Loading

    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView(String(localized: "Loading summary..."))
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Failed

    var failedView: some View {
        ContentUnavailableView {
            Label(String(localized: "Could not load summary"), systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: 8) {
                Text("Something went wrong while saving your workout.")
                #if DEBUG
                Text(store.failureDebugInfo)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                #endif
            }
        } actions: {
            failedCloseButton
        }
    }

    private var failedCloseButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Text(String(localized: "Close"))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.bordered)
        .tint(.gray)
    }
}
