//
//  JoinLiveClassView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: JoinLiveClassFeature.self)
struct JoinLiveClassView: View {

    @Bindable var store: StoreOf<JoinLiveClassFeature>

    var body: some View {
        VStack(spacing: 32) {
            content
            Spacer()
            actionButton
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .onAppear { send(.viewDidAppear) }
    }

    // MARK: - Private views (struktura)

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle:
            idleContent
        case .searching:
            searchingContent
        case .connected:
            connectedContent
        }
    }

    private var idleContent: some View {
        VStack(spacing: 16) {
            iconImage(symbol: "wave.3.right.circle", color: .blue)
            Text(idleTitle).font(.title2).foregroundStyle(.primary)
            Text(idleSubtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            nickRow
        }
    }

    private var searchingContent: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(2)
            Text(searchingTitle).font(.title2).foregroundStyle(.primary)
            Text(nickRowText).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var connectedContent: some View {
        VStack(spacing: 16) {
            iconImage(symbol: "checkmark.circle.fill", color: .green)
            Text(connectedTitle).font(.title2).foregroundStyle(.primary)
            Text(connectedSubtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text(nickRowText).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var nickRow: some View {
        HStack {
            Text(nickRowText)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch store.phase {
        case .idle:
            joinButton
        case .searching, .connected:
            leaveButton
        }
    }

    private var joinButton: some View {
        Button {
            send(.joinTapped)
        } label: {
            Text(joinTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(.blue))
        }
    }

    private var leaveButton: some View {
        Button {
            send(.leaveTapped)
        } label: {
            Text(leaveTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(.red))
        }
    }

    private func iconImage(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 80))
            .foregroundStyle(color)
    }

    // MARK: - Private content (implementacja)

    private var background: some View {
        Color(.systemBackground)
    }

    private var nickRowText: String {
        String(localized: "Nick: \(store.nick)", bundle: .main)
    }

    private var idleTitle: String { String(localized: "Join a Live Class", bundle: .main) }
    private var idleSubtitle: String { String(localized: "Tap Join to broadcast your heart rate to the Gym Room display.", bundle: .main) }
    private var searchingTitle: String { String(localized: "Looking for class...", bundle: .main) }
    private var connectedTitle: String { String(localized: "Broadcasting", bundle: .main) }
    private var connectedSubtitle: String { String(localized: "Your heart rate is visible on the Gym Room display.", bundle: .main) }
    private var joinTitle: String { String(localized: "Join Live Class", bundle: .main) }
    private var leaveTitle: String { String(localized: "Leave", bundle: .main) }
}

#Preview("Idle") {
    JoinLiveClassView(
        store: Store(initialState: JoinLiveClassFeature.State()) {
            JoinLiveClassFeature()
        }
    )
}
