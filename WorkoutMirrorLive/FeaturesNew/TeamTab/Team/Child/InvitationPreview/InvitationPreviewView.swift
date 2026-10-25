//
//  InvitationPreviewView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: InvitationPreviewFeature.self)
struct InvitationPreviewView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<InvitationPreviewFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            phaseContent
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        closeButton
                    }
                }
        }
    }

    // MARK: - Phases (structure)

    @ViewBuilder
    private var phaseContent: some View {
        switch store.phase {
        case .scanning:
            scanner
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .preview(invitation, state):
            invitationCard(invitation, state: state)
        case let .failure(failure):
            failureView(failure)
        }
    }

    private func invitationCard(_ invitation: TeamInvitation, state: TeamInvitationState) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                invitationHeader(invitation)
                invitationFacts(invitation)
                invitationActions(state)
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func invitationActions(_ state: TeamInvitationState) -> some View {
        switch state {
        case .pending, .declined:
            pendingActions
        case .accepted:
            alreadyMemberText
        case .expired, .revoked:
            closedText
        }
    }

    // MARK: - Implementation

    private var scanner: some View {
        QRScannerView { code in
            send(.codeScanned(code))
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .bottom) {
            Text(scanHint)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: .capsule)
                .padding(.bottom, 40)
        }
    }

    private func invitationHeader(_ invitation: TeamInvitation) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text(invitation.invite.groupName)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(String(localized: "\(invitation.invite.createdByName) invites you to a private group"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func invitationFacts(_ invitation: TeamInvitation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(privacyText, systemImage: "lock")
            Label(
                String(localized: "Valid until \(invitation.invite.expiresAt.formatted(date: .abbreviated, time: .shortened))"),
                systemImage: "clock"
            )
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 14))
    }

    private var pendingActions: some View {
        VStack(spacing: 10) {
            joinButton
            HStack(spacing: 10) {
                laterButton
                declineButton
            }
        }
        .disabled(store.isResponding)
    }

    private var joinButton: some View {
        Button {
            send(.joinTapped)
        } label: {
            Group {
                if store.isResponding {
                    ProgressView()
                } else {
                    Text(joinTitle)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var laterButton: some View {
        Button {
            send(.laterTapped)
        } label: {
            Text(laterTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var declineButton: some View {
        Button(role: .destructive) {
            send(.declineTapped)
        } label: {
            Text(declineTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var alreadyMemberText: some View {
        Label(alreadyMemberMessage, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
    }

    private var closedText: some View {
        Label(InvitationPreviewFailure.closed.message, systemImage: "clock.badge.xmark")
            .foregroundStyle(.secondary)
    }

    private func failureView(_ failure: InvitationPreviewFailure) -> some View {
        ContentUnavailableView {
            Label(failure.title, systemImage: "qrcode")
        } description: {
            Text(failure.message)
        } actions: {
            scanAgainButton
        }
    }

    private var scanAgainButton: some View {
        Button {
            send(.scanAgainTapped)
        } label: {
            Text(scanAgainTitle)
        }
    }

    private var closeButton: some View {
        Button {
            send(.closeTapped)
        } label: {
            Text(closeTitle)
        }
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "Join a Group")
    private let scanHint = String(localized: "Point the camera at an invite code")
    private let privacyText = String(localized: "Members see your name and your results for this group's plans — nothing else from your health data.")
    private let joinTitle = String(localized: "Join")
    private let laterTitle = String(localized: "Later")
    private let declineTitle = String(localized: "Decline")
    private let alreadyMemberMessage = String(localized: "You're already in this group.")
    private let scanAgainTitle = String(localized: "Scan Again")
    private let closeTitle = String(localized: "Close")
}
