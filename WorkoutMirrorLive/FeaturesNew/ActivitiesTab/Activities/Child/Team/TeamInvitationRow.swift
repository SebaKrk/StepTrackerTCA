//
//  TeamInvitationRow.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import SharedModels
import SwiftUI

/// One pending invitation: who invites, with decline and join side by side.
struct TeamInvitationRow: View {

    // MARK: - Properties

    let invitation: TeamInvitation
    let isResponding: Bool
    let onJoin: () -> Void
    let onDecline: () -> Void

    // MARK: - Body (structure)

    var body: some View {
        GroupBox {
            HStack(spacing: 10) {
                titles
                Spacer(minLength: 0)
                declineButton
                joinButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
        .disabled(isResponding)
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(invitation.invite.groupName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(String(localized: "From \(invitation.invite.createdByName)"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Implementation

    private var declineButton: some View {
        Button(role: .destructive, action: onDecline) {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(declineTitle)
    }

    private var joinButton: some View {
        Button(action: onJoin) {
            if isResponding {
                ProgressView()
            } else {
                Text(joinTitle)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.glassProminent)
    }

    // MARK: - Text

    private let joinTitle = String(localized: "Join")
    private let declineTitle = String(localized: "Decline")
}
